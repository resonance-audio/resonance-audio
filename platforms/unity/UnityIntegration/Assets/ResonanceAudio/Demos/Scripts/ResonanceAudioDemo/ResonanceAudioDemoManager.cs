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

/// Class that manages the ResonanceAudioDemo scene.
public class ResonanceAudioDemoManager : MonoBehaviour {
  /// Main camera.
  public Camera mainCamera;

  /// Cube controller.
  public ResonanceAudioDemoCubeController cube;

  void Start() {
    Screen.sleepTimeout = SleepTimeout.NeverSleep;
  }

  void Update() {
#if !UNITY_EDITOR
    if (Input.GetKeyDown(KeyCode.Escape)) {
      Application.Quit();
    }
#endif  // !UNITY_EDITOR
    // Raycast against the cube.
    Ray ray = mainCamera.ViewportPointToRay(0.5f * Vector2.one);
    RaycastHit hit;
    bool cubeHit = Physics.Raycast(ray, out hit) && hit.transform == cube.transform;
    // Update the state of the cube.
    cube.SetGazedAt(cubeHit);
    if (cubeHit) {
      if((Input.touchCount == 0 && Input.GetMouseButtonDown(0)) ||    // LMB for desktop.
         (Input.touchCount > 0 && Input.GetTouch(0).tapCount > 1 &&   // Double-tap for mobile.
          Input.GetTouch(0).phase == TouchPhase.Began)) {
        // Teleport the cube to its next location.
        cube.TeleportRandomly();
      }
    }
  }
}
