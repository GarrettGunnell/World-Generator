using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugMaps : MonoBehaviour {
    public ComputeShader mapGenerator;

    private RenderTexture target;

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (target == null) {
            target = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            target.enableRandomWrite = true;
            target.Create();
        }

        Graphics.Blit(target, destination);
    }
}
