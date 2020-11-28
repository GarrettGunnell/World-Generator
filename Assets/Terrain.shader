Shader "Custom/Terrain" {
    Properties {

    }

    SubShader {

        Pass {
            CGPROGRAM
            
            #pragma vertex vp
            #pragma fragment fp

            struct VertexData {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 pos : SV_POSITION;
            };

            v2f vp(VertexData v) {
                v2f f;
                f.pos = UnityObjectToClipPos(v.vertex);

                return f;
            }

            float4 fp(v2f f) : SV_TARGET {
                return 1;
            }

            ENDCG
        }
    }
}
