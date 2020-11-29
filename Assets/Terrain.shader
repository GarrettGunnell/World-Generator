Shader "Custom/Terrain" {
    Properties {
        _Albedo ("Albedo", Color) = (1, 1, 1)
        _WireframeThickness ("Wireframe Thickness", Range(0.01, 10)) = 1
        _WireframeOn ("Toggle Wireframe", Int) = 1
    }

    SubShader {

        Pass {
            CGPROGRAM
            
            #pragma vertex vp
            #pragma geometry gp
            #pragma fragment fp

            float3 _Albedo;
            float _WireframeThickness;
            int _WireframeOn;

            struct VertexData {
                float4 vertex : POSITION;
            };

            struct v2g {
                float4 pos : SV_POSITION;
            };

            v2g vp(VertexData v) {
                v2g g;
                g.pos = UnityObjectToClipPos(v.vertex);

                return g;
            }

            struct g2f {
                v2g data;
                float2 barycentricCoordinates : TEXCOORD0;
            };

            [maxvertexcount(3)]
            void gp(triangle v2g g[3], inout TriangleStream<g2f> stream) {
                g2f g0, g1, g2;
                g0.data = g[0];
                g1.data = g[1];
                g2.data = g[2];

                g0.barycentricCoordinates = float2(1, 0);
                g1.barycentricCoordinates = float2(0, 1);
                g2.barycentricCoordinates = float2(0, 0);

                stream.Append(g0);
                stream.Append(g1);
                stream.Append(g2);
            }

            float getWireframe(g2f f) {
                float3 barys;
                barys.xy = f.barycentricCoordinates;
                barys.z = 1 - barys.x - barys.y;
                float3 deltas = fwidth(barys);
                barys = smoothstep(deltas * _WireframeThickness, (deltas * _WireframeThickness) + deltas, barys);
                float minBary = min(barys.x, min(barys.y, barys.z));

                return minBary;
            }

            float4 fp(g2f f) : SV_TARGET {
                float3 albedo = _WireframeOn ? _Albedo * getWireframe(f) : _Albedo;

                return float4(albedo, 1);
            }

            ENDCG
        }
    }
}
