using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugMaps : MonoBehaviour {
    public ComputeShader mapGenerator;
    public bool updateMap = false;
    public bool exportMap = false;

    private RenderTexture map;
    public int seed;

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
        if (map == null) {
            map = new RenderTexture(source.width, source.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            map.enableRandomWrite = true;
            map.Create();
        }

        mapGenerator.SetTexture(0, "_HeightMap", map);
        mapGenerator.SetInt("_Seed", seed);
        mapGenerator.SetInt("_Height", map.height);
        mapGenerator.SetInt("_Width", map.width);
        int threadGroupsX = Mathf.CeilToInt(map.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(map.height / 8.0f);
        mapGenerator.Dispatch(0, threadGroupsX, threadGroupsY, 1);
        
        Graphics.Blit(map, destination);
    }

    private void LateUpdate() {
        if (exportMap) {
            RenderTexture rt = new RenderTexture(786, 629, 24);
            GetComponent<Camera>().targetTexture = rt;
            Texture2D screenshot = new Texture2D(786, 629, TextureFormat.RGB24, false);
            GetComponent<Camera>().Render();
            RenderTexture.active = rt;
            screenshot.ReadPixels(new Rect(0, 0, 786, 629), 0, 0);
            GetComponent<Camera>().targetTexture = null;
            RenderTexture.active = null;
            Destroy(rt);
            string filename = string.Format("{0}/../Maps/map_{1}.png", Application.dataPath, System.DateTime.Now.ToString("HH-mm-ss"));
            System.IO.File.WriteAllBytes(filename, screenshot.EncodeToPNG());
            exportMap = false;
        }
    }
}
