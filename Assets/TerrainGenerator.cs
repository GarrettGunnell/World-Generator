using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainGenerator : MonoBehaviour {
    public int seed;
    public bool updateMap;
    public bool exportMap;

    private HeightMapGenerator mapGenerator;

    private void Awake() {
        seed = Random.Range(1, 1000000);
        mapGenerator = new HeightMapGenerator(256, 256);
        mapGenerator.GenerateMap(seed);
        GetComponent<Renderer>().sharedMaterial.SetTexture("_HeightMap", mapGenerator.GetMap());
    }

    private void Update() {
        if (updateMap) {
            seed = Random.Range(1, 1000000);
            mapGenerator.GenerateMap(seed);
            updateMap = false;
            GetComponent<Renderer>().sharedMaterial.SetTexture("_HeightMap", mapGenerator.GetMap());
        }
    }



}
