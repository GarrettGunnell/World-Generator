using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeightMapGenerator {

    private RenderTexture map;
    private ComputeShader computeMap;

    public HeightMapGenerator(int width, int height) {
        if (map == null) {
            map = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            map.enableRandomWrite = true;
            map.Create();
        }

        computeMap = (ComputeShader)Resources.Load("MapGenerator");
        computeMap.SetTexture(0, "_Result", map);
    }

    public RenderTexture GenerateMap(uint seed) {
        computeMap.SetInt("_Seed", (int)seed);
        int threadGroupsX = Mathf.CeilToInt(map.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(map.height / 8.0f);
        computeMap.Dispatch(0, threadGroupsX, threadGroupsY, 1);

        return map;
    }
}
