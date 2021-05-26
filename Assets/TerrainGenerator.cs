using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainGenerator : MonoBehaviour {
    public int height = 256;
    public int width = 256;
    public int seed;

    [Range(1, 32)]
    public int octaves = 16;
    [Range(0.5f, 1)]
    public float selfSimilarity = 1.0f;
    [Range(0.0001f, 0.05f)]
    public float frequency = 1.0f;
    [Range(0.01f, 5.0f)]
    public float amplitude = 1.0f;
    [Range(0.1f, 3.0f)]
    public float lacunarity = 2.0f;

    public enum NormalCalculation {
        NoChange = 0,
        AmplitudeMult,
        AmplitudeFreqMult
    } public NormalCalculation normalCalculation;

    public bool updateMap;
    public bool randomizeSeed;
    public bool exportMap;
    
    private RenderTexture map;
    private ComputeShader computeMap;

    public void GenerateMap() {
        computeMap.SetInt("_Seed", seed);
        computeMap.SetInt("_Octaves", octaves);
        computeMap.SetFloat("_SelfSimilarity", selfSimilarity);
        computeMap.SetFloat("_Frequency", frequency);
        computeMap.SetFloat("_Amplitude", amplitude);
        computeMap.SetFloat("_Lacunarity", lacunarity);
        computeMap.SetInt("_NormalCalculation", (int)normalCalculation);
        int threadGroupsX = Mathf.CeilToInt(map.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(map.height / 8.0f);
        computeMap.Dispatch(0, threadGroupsX, threadGroupsY, 1);
    }

    private void Awake() {
        seed = Random.Range(1, 100000);

        if (map == null) {
            map = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            map.enableRandomWrite = true;
            map.Create();
        }

        computeMap = Resources.Load<ComputeShader>("MapGenerator");
        computeMap.SetInt("_Width", map.width);
        computeMap.SetInt("_Height", map.height);
        computeMap.SetTexture(0, "_HeightMap", map);


        GenerateMap();
        GetComponent<Renderer>().sharedMaterial.SetTexture("_HeightMap", map);

        Mesh mesh = GetComponent<MeshFilter>().mesh;
        mesh.bounds = new Bounds(mesh.bounds.center, new Vector3(mesh.bounds.size.x, 10000, mesh.bounds.size.z));
    }

    private void Update() {
        if (updateMap) {
            if (randomizeSeed)
                seed = Random.Range(1, 1000000);
            GenerateMap();
            updateMap = false;
            GetComponent<Renderer>().sharedMaterial.SetTexture("_HeightMap", map);
        }
    }



}
