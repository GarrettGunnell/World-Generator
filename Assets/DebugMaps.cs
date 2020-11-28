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

        int kernel = mapGenerator.FindKernel("CSMain");
        mapGenerator.SetTexture(kernel, "Result", target);
        int threadGroupsX = Mathf.CeilToInt(target.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(target.height / 8.0f);
        mapGenerator.Dispatch(kernel, threadGroupsX, threadGroupsY, 1);
        
        Graphics.Blit(target, destination);
    }
}
