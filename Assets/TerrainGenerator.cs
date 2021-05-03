using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainGenerator : MonoBehaviour {
    public int seed;
    public bool updateMap;
    public bool exportMap;

    private RenderTexture map;
    private HeightMapGenerator mapGenerator;

    private void Awake() {
        seed = Random.Range(1, 1000000);
        mapGenerator = new HeightMapGenerator(512, 512);
        map = mapGenerator.GenerateMap(seed);
        GetComponent<Renderer>().sharedMaterial.SetTexture("_HeightMap", map);
    }

    private void Update() {
        if (updateMap) {
            seed = Random.Range(1, 1000000);
            map = mapGenerator.GenerateMap(seed);
            updateMap = false;
        }
    }



}
