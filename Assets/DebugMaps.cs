using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugMaps : MonoBehaviour {
    public ComputeShader mapGenerator;
    public bool updateMap = false;

    private RenderTexture target;
    private int seed;

    private void Awake() {
        seed = Random.Range(1, 10000000);
    }

    private void Update() {
        if (updateMap) {
            seed = Random.Range(1, 10000000);
            updateMap = false;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (target == null) {
            target = new RenderTexture(source.width, source.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            target.enableRandomWrite = true;
            target.Create();
        }

        int kernel = mapGenerator.FindKernel("CSMain");
        mapGenerator.SetTexture(kernel, "Result", target);
        mapGenerator.SetInt("_Seed", seed);
        int threadGroupsX = Mathf.CeilToInt(target.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(target.height / 8.0f);
        mapGenerator.Dispatch(kernel, threadGroupsX, threadGroupsY, 1);
        
        Graphics.Blit(target, destination);
    }
}
