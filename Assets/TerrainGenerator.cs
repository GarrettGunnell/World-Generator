using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainGenerator : MonoBehaviour {
    public int height = 256;
    public int width = 256;
    public int seed;
    public bool updateMap;
    public bool exportMap;
    
    private RenderTexture map;
    private RenderTexture normals;
    private ComputeShader computeMap;

    public void GenerateMap() {
        computeMap.SetInt("_Seed", seed);
        int threadGroupsX = Mathf.CeilToInt(map.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(map.height / 8.0f);
        computeMap.Dispatch(0, threadGroupsX, threadGroupsY, 1);
        computeMap.Dispatch(1, threadGroupsX, threadGroupsY, 1);
    }

    private void Awake() {
        seed = Random.Range(1, 1000000);

        if (map == null) {
            map = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            map.enableRandomWrite = true;
            map.Create();
        }

        if (normals == null) {
            normals = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            normals.enableRandomWrite = true;
            normals.Create();
        }

        computeMap = Resources.Load<ComputeShader>("MapGenerator");
        computeMap.SetTexture(0, "_HeightMap", map);
        computeMap.SetTexture(1, "_HeightMap", map);
        computeMap.SetTexture(1, "_NormalMap", normals);


        GenerateMap();
        GetComponent<Renderer>().sharedMaterial.SetTexture("_HeightMap", map);
        GetComponent<Renderer>().sharedMaterial.SetTexture("_NormalMap", normals);

        Mesh mesh = GetComponent<MeshFilter>().mesh;
        mesh.bounds = new Bounds(mesh.bounds.center, new Vector3(mesh.bounds.size.x, 10000, mesh.bounds.size.z));
    }

    private void Update() {
        if (updateMap) {
            seed = Random.Range(1, 1000000);
            GenerateMap();
            updateMap = false;
            GetComponent<Renderer>().sharedMaterial.SetTexture("_HeightMap", map);
        }
    }



}
