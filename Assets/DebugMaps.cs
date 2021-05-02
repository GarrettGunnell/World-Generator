using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugMaps : MonoBehaviour {
    public bool updateMap = false;
    public bool exportMap = false;

    private RenderTexture map;
    private HeightMapGenerator mapGenerator;
    public int seed;

    private void Awake() {
        seed = Random.Range(1, 10000000);

        mapGenerator = new HeightMapGenerator(786, 629);
        map = mapGenerator.GenerateMap(seed);
    }

    private void Update() {
        if (updateMap) {
            seed = Random.Range(1, 10000000);
            map = mapGenerator.GenerateMap(seed);
            updateMap = false;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
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
