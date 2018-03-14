// Copyright 2017 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using UnityEngine;

/// Resonance Audio demo cube controller.
[RequireComponent(typeof(Renderer))]
public class ResonanceAudioDemoCubeController : MonoBehaviour {
  // Visual material of the cube.
  private Material material = null;

  void Start() {
    material = GetComponent<Renderer>().material;
    SetGazedAt(false);
  }

  /// Sets the gaze state.
  public void SetGazedAt(bool gazedAt) {
    material.color = gazedAt ? Color.green : Color.red;
  }

  /// Teleports the cube to a random location.
  public void TeleportRandomly() {
    Vector3 direction = Random.onUnitSphere;
    direction.y = Mathf.Clamp(direction.y, 0.5f, 1.0f);
    float distance = 2.0f * Random.value + 1.5f;
    transform.localPosition = distance * direction;
  }
}
