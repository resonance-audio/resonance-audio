/*
Copyright 2018 Google Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "utils/lockless_task_queue.h"

#include "base/logging.h"

namespace vraudio {

LocklessTaskQueue::LocklessTaskQueue(size_t max_tasks) {
  CHECK_GT(max_tasks, 0U);
  Init(max_tasks);
}

LocklessTaskQueue::~LocklessTaskQueue() { Clear(); }

void LocklessTaskQueue::Post(Task&& task) {
  Node* const free_node = PopNodeFromList(&free_list_head_);
  if (free_node == nullptr) {
    LOG(WARNING) << "Queue capacity reached - dropping task";
    return;
  }
  free_node->task = std::move(task);
  PushNodeToList((NodeAndTag*)&task_list_head_, free_node);
}

void LocklessTaskQueue::Execute() {
  ProcessTaskList(true /*execute_tasks*/);
}

void LocklessTaskQueue::Clear() {
  ProcessTaskList(false /*execute_tasks*/);
}

void LocklessTaskQueue::PushNodeToList(NodeAndTag* list_head,
  Node* node) {
  DCHECK(list_head);
  DCHECK(node);
  NodeAndTag nodeSwap;
  nodeSwap.single.offset = offset(node);
  NodeAndTag list_head_compare;
  uint32_t tag = tag_counter_.fetch_add(1);
  list_head_compare.single.tag = tag;
  do {
    list_head_compare.single.offset = list_head->single.offset.load(std::memory_order_relaxed);
    list_head->single.tag.store(tag, std::memory_order_relaxed);
    node->next.store(ptr(&list_head_compare), std::memory_order_relaxed);
  } while (!list_head->both_atomic.compare_exchange_strong(list_head_compare.both, nodeSwap.both,
    std::memory_order_release, std::memory_order_acquire));
}

LocklessTaskQueue::Node* LocklessTaskQueue::PopNodeFromList(
  NodeAndTag* list_head) {
  DCHECK(list_head);
  NodeAndTag list_head_compare;
  NodeAndTag list_head_swap;
  uint32_t tag = tag_counter_.fetch_add(1);
  list_head_compare.single.tag = tag;
  do {
    list_head_compare.single.offset = list_head->single.offset.load(std::memory_order_relaxed);
    if (list_head_compare.single.offset == (uint32_t)-1) {
      // End of list reached.
      return nullptr;
    }
    list_head->single.tag.store(tag, std::memory_order_relaxed);
    list_head_swap.single.offset = offset(ptr(&list_head_compare)->next);
  } while (!list_head->both_atomic.compare_exchange_strong(list_head_compare.both, list_head_swap.both, std::memory_order_acquire,
    std::memory_order_relaxed));
  return ptr(&list_head_compare);
}

void LocklessTaskQueue::ProcessTaskList(bool execute) {
  NodeAndTag nullNodeAndTag;
  nullNodeAndTag.single.offset = (uint32_t)-1;
  nullNodeAndTag.single.tag = (uint32_t)-1;
  NodeAndTag old_task_list_head;
  old_task_list_head.both = task_list_head_.both_atomic.exchange(nullNodeAndTag.both);

  Node* node_itr = ptr(&old_task_list_head);
  while (node_itr != nullptr) {
    Node* next_node_ptr = node_itr->next;
    temp_tasks_.emplace_back(std::move(node_itr->task));
    node_itr->task = nullptr;
    PushNodeToList((NodeAndTag*)&free_list_head_, node_itr);
    node_itr = next_node_ptr;
  }

  if (execute) {
    // Execute tasks in reverse order.
    for (std::vector<Task>::reverse_iterator task_itr = temp_tasks_.rbegin();
         task_itr != temp_tasks_.rend(); ++task_itr) {
      if (*task_itr != nullptr) {
        (*task_itr)();
      }
    }
  }
  temp_tasks_.clear();
}

void LocklessTaskQueue::Init(size_t num_nodes) {
  nodes_.resize(num_nodes);
  temp_tasks_.reserve(num_nodes);
  tag_counter_.store(0);

  // Initialize free list.
  base_ = (uintptr_t)&nodes_[0];
  free_list_head_.single.offset = 0;
  for (size_t i = 0; i < num_nodes - 1; ++i) {
    nodes_[i].next = &nodes_[i + 1];
  }
  nodes_[num_nodes - 1].next = nullptr;

  // Initialize task list.
  task_list_head_.single.offset = (uint32_t)-1;
}

}  // namespace vraudio
