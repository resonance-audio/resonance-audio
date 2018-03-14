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

/// First-person player controller for Resonance Audio demo scenes.
[RequireComponent(typeof(CharacterController))]
public class DemoPlayerController : MonoBehaviour {
  /// Camera.
  public Camera mainCamera;

  // Character controller.
  private CharacterController characterController = null;

  // Player movement speed.
  private float movementSpeed = 5.0f;

  // Target camera rotation in degrees.
  private float rotationX = 0.0f;
  private float rotationY = 0.0f;

  // Maximum allowed vertical rotation angle in degrees.
  private const float clampAngleDegrees = 80.0f;

  // Camera rotation sensitivity.
  private const float sensitivity = 2.0f;

  void Start() {
    characterController = GetComponent<CharacterController>();
    Vector3 rotation = mainCamera.transform.localRotation.eulerAngles;
    rotationX = rotation.x;
    rotationY = rotation.y;
  }

  void LateUpdate() {
#if UNITY_EDITOR
    if (Input.GetMouseButtonDown(0)) {
      SetCursorLock(true);
    } else if (Input.GetKeyDown(KeyCode.Escape)) {
      SetCursorLock(false);
    }
#endif  // UNITY_EDITOR
    // Update the rotation.
    float mouseX = Input.GetAxis("Mouse X");
    float mouseY = -Input.GetAxis("Mouse Y");
    if (Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Began) {
      // Note that multi-touch control is not supported on mobile devices.
      mouseX = 0.0f;
      mouseY = 0.0f;
    }
    rotationX += sensitivity * mouseY;
    rotationY += sensitivity * mouseX;
    rotationX = Mathf.Clamp(rotationX, -clampAngleDegrees, clampAngleDegrees);
    mainCamera.transform.localRotation = Quaternion.Euler(rotationX, rotationY, 0.0f);
    // Update the position.
    float movementX = Input.GetAxis("Horizontal");
    float movementY = Input.GetAxis("Vertical");
    Vector3 movementDirection = new Vector3(movementX, 0.0f, movementY);
    movementDirection = mainCamera.transform.localRotation * movementDirection;
    movementDirection.y = 0.0f;
    characterController.SimpleMove(movementSpeed * movementDirection);
  }

  // Sets the cursor lock for first-person control.
  private void SetCursorLock(bool lockCursor) {
    if (lockCursor) {
      Cursor.lockState = CursorLockMode.Locked;
      Cursor.visible = false;
    } else {
      Cursor.lockState = CursorLockMode.None;
      Cursor.visible = true;
    }
  }
}
