Shader "Hamilt79/Overlay"{
    Properties{
        // Default texture when no video is provided
        _MainTex ("Texture", 2D) = "white" {}
        // Tint/alpha
        _Color("Color", Color) = (1,1,1,1)
        // VR Distance
        _Dist("Distance", Float) = 1.0
        // Plane Width
        _Width("Width", Float) = 1.0
        // Plane Height
        _Height("Height", Float) = 1.0
        // Plane Scale
        _Scale("Scale", Float) = 1.0
        // X Position across screen
        _XPos("XPos", Float) = 0.0
        // Y position across screen
        _YPos("YPos", Float) = 0.0
        // Enable ST support (if the world supports it)
        [ToggleUI] _WorldSt("World ST", Float) = 0.0
        // Enable timeline at the bottom
        [ToggleUI] _Timeline("Timeline", Float) = 0.0
        // Enable volume indicator on right
        [ToggleUI] _Volume("Volume", Float) = 0.0
    }
        SubShader{
            Tags { "RenderType" = "Transparent" "QUEUE" = "Overlay" }
            LOD 100
            // Allow transparency
            Blend SrcAlpha OneMinusSrcAlpha
            // Show through walls
            ZTest Always
            // No depth buffer
            ZWrite Off
            Cull Front

            Pass{
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };

                // Property declarations
                float4 _Color;
                float _Dist;
                float _Width;
                float _Height;
                float _YPos;
                float _XPos;
                float _Scale;
                float _WorldSt;
                sampler2D _MainTex;
                float4 _MainTex_ST;

                // Generated from shadergraph and slightly modified
                float3 Unity_RotateAboutAxis_Degrees_float(float3 In, float3 Axis, float Rotation)
                {
                    Rotation = radians(Rotation);
                    float s = sin(Rotation);
                    float c = cos(Rotation);
                    float one_minus_c = 1.0 - c;

                    Axis = normalize(Axis);
                    float3x3 rot_mat = 
                    {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
                        one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
                        one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
                    };
                    return mul(rot_mat,  In);
                }

                v2f vert(appdata v) {
                    v2f o;

                    // Get camera position
                    float3 camPos = _WorldSpaceCameraPos;
                    // Get world position of current gameobject
                    float3 baseWorldPos = unity_ObjectToWorld._m03_m13_m23;
                    // Get difference between the positions
                    float3 xDif = camPos.xyz - baseWorldPos.xyz;
                    
                    // Apply scaling, width, height
                    v.vertex.xyz *= _Scale;
                    v.vertex.x *= _Width;
                    v.vertex.z *= _Height;
                    // Rotate the screen as the x and y position changes so it faces the camera in VR
                    v.vertex.xyz = Unity_RotateAboutAxis_Degrees_float(v.vertex.xyz, float3(0.0, 0.0, 1.0), -1 * _XPos * 2);
                    v.vertex.xyz = Unity_RotateAboutAxis_Degrees_float(v.vertex.xyz, float3(1.0, 0.0, 0.0), -1 * _YPos * 2);
                    // Distance offset
                    v.vertex.y += 20;

                    // Move the gameobject left or right depending on eye to create the illusion of distance
                    if (unity_StereoEyeIndex == 0) {
                        v.vertex.x += _Dist;
                    } else {
                        v.vertex.x -= _Dist;
                    }
                    
                    // Convert local space to world space
                    v.vertex = mul(unity_ObjectToWorld, v.vertex);
                    // Bring gameobject to camera
                    v.vertex.xyz += xDif.xyz;
                    // Convert back to local space
                    v.vertex = mul(unity_WorldToObject, v.vertex);
                    // Move left and right
                    v.vertex.x += _XPos;
                    // Move up and down
                    v.vertex.z -= _YPos;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    return o;
                }

                // Global texture from Pro TV
                uniform sampler2D _Udon_VideoTex;
                float4 _Udon_VideoTex_TexelSize;
                float4 _Udon_VideoTex_ST;

                fixed4 frag(v2f i) : SV_Target{
                    // Invert X
                    i.uv.x = 1.0 - i.uv.x;
                    // If no video is found display default texture
                    if (_Udon_VideoTex_TexelSize.z <= 16) {
                        return tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
                    } else {
                        if (_WorldSt == 1.0) {
                            i.uv = TRANSFORM_TEX(i.uv, _Udon_VideoTex);
                        }
                        float4 tex = tex2D(_Udon_VideoTex, i.uv);
                        return (tex * _Color);
                    }

                }
                ENDCG
            }

            // Timeline pass
            // For most of this look at the previous pass for comments
            // I know repeating code is bad but there is literally no other
            // way to do it in this case (to my knowledge)
			Pass{
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };

                float4 _Color;
                float _Dist;
                float _Width;
                float _Height;
                float _YPos;
                float _XPos;
                float _Scale;
                float _WorldSt;

                // Generated from shadergraph and slightly modified
                float3 Unity_RotateAboutAxis_Degrees_float(float3 In, float3 Axis, float Rotation)
                {
                    Rotation = radians(Rotation);
                    float s = sin(Rotation);
                    float c = cos(Rotation);
                    float one_minus_c = 1.0 - c;

                    Axis = normalize(Axis);
                    float3x3 rot_mat = 
                    {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
                        one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
                        one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
                    };
                    return mul(rot_mat,  In);
                }
				
				float _Timeline;

                v2f vert(appdata v) {
                    v2f o;
					if (_Timeline != 1.0){
                        o.uv = 0;
                        o.vertex = 0;
                        return o;
                    }
                    float3 camPos = _WorldSpaceCameraPos;
                    float3 baseWorldPos = unity_ObjectToWorld._m03_m13_m23;
                    float3 xDif = camPos.xyz - baseWorldPos.xyz;
                    
                    v.vertex.xyz *= _Scale;
                    v.vertex.z *= 1.2;
                    //v.vertex.z *= .04;
                    v.vertex.x *= _Width;
                    v.vertex.z *= _Height;
                    
                    v.vertex.xyz = Unity_RotateAboutAxis_Degrees_float(v.vertex.xyz, float3(0.0, 0.0, 1.0), -1 * _XPos * 2);
                    v.vertex.xyz = Unity_RotateAboutAxis_Degrees_float(v.vertex.xyz, float3(1.0, 0.0, 0.0), -1 * _YPos * 2);
                    v.vertex.y += 20;
					

                    if (unity_StereoEyeIndex == 0) {
                        v.vertex.x += _Dist;
                    } else {
                        v.vertex.x -= _Dist;
                    }
                    
                    v.vertex = mul(unity_ObjectToWorld, v.vertex);
                    v.vertex.xyz += xDif.xyz;
                    v.vertex = mul(unity_WorldToObject, v.vertex);
                    
                    v.vertex.x += _XPos;
                    v.vertex.z -= _YPos;
                    //v.vertex.z += 3.1;
					//v.vertex.z += (_Scale - 1) * 3.1;
                  
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    return o;
                }

                uniform sampler2D _Udon_VideoTex;
                float4 _Udon_VideoTex_TexelSize;
                float4 _Udon_VideoTex_ST;
                float4x4 _Udon_VideoData;

                fixed4 frag(v2f i) : SV_Target{

                    // If timeline isnt enabled simply do not render anything here
					if (_Timeline != 1.0){
                        discard;
                    }

                    i.uv.x = 1.0 - i.uv.x;
					float per = _Udon_VideoData[1][1];
                    float yShift = .45;
                    i.uv.y += yShift;
                    float yCut = .025;
                    // Cutting off parts of the plane so only a thin bar is shown
                    if (i.uv.y >= (.5 + yCut) || i.uv.y <= (.5 - yCut)) {
                        discard;
                    }
                    float lineSize = .005;
                    float cursorSize = 0.005 / _Width;
                    if (abs(i.uv.x - per) < cursorSize) {
                        return float4(1.0, 1.0, 1.0, _Color.a);
                    } else {
                        if(i.uv.y >= (.5 + lineSize) || i.uv.y <= (.5 - lineSize)){
                            discard;
                        }
                    }
                    if (per > i.uv.x){
                        return float4(1.0, 1.0, 0.6, _Color.a);
                    }
                    return float4(0.3, 0.3, 0.3, _Color.a);

                }
                ENDCG
            }

            // Volume indicator pass
            // For most of this look at the previous pass for comments
            // I know repeating code is bad but there is literally no other
            // way to do it in this case (to my knowledge)
            Pass{
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };

                float4 _Color;
                float _Dist;
                float _Width;
                float _Height;
                float _YPos;
                float _XPos;
                float _Scale;
                float _WorldSt;

                // Generated from shadergraph and slightly modified
                float3 Unity_RotateAboutAxis_Degrees_float(float3 In, float3 Axis, float Rotation)
                {
                    Rotation = radians(Rotation);
                    float s = sin(Rotation);
                    float c = cos(Rotation);
                    float one_minus_c = 1.0 - c;

                    Axis = normalize(Axis);
                    float3x3 rot_mat = 
                    {   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
                        one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
                        one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
                    };
                    return mul(rot_mat,  In);
                }
				
				float _Volume;

                v2f vert(appdata v) {
                    v2f o;
					if (_Volume != 1.0){
                        o.uv = 0;
                        o.vertex = 0;
                        return o;
                    }
                    float3 camPos = _WorldSpaceCameraPos;
                    float3 baseWorldPos = unity_ObjectToWorld._m03_m13_m23;
                    float3 xDif = camPos.xyz - baseWorldPos.xyz;
                    v.vertex.xyz *= _Scale;
                    v.vertex.x *= 1.1 + (_Width - 1);

                    //v.vertex.x *= _Width;
                    v.vertex.z *= _Height;
                    v.vertex.xyz = Unity_RotateAboutAxis_Degrees_float(v.vertex.xyz, float3(0.0, 0.0, 1.0), -1 * _XPos * 2);
                    v.vertex.xyz = Unity_RotateAboutAxis_Degrees_float(v.vertex.xyz, float3(1.0, 0.0, 0.0), -1 * _YPos * 2);
                    v.vertex.y += 20;
					//v.vertex.x += (_Width - 1) * 12.5;
					///v.vertex.x += (_Width - 1) * 12.5;

                    if (unity_StereoEyeIndex == 0) {
                        v.vertex.x += _Dist;
                    } else {
                        v.vertex.x -= _Dist;
                    }
                    
                    v.vertex = mul(unity_ObjectToWorld, v.vertex);
                    v.vertex.xyz += xDif.xyz;
                    v.vertex = mul(unity_WorldToObject, v.vertex);
                    v.vertex.x += _XPos;
                    v.vertex.z -= _YPos;
                    //v.vertex.x += 6.3;
					//v.vertex.x += (_Scale - 1) * 6.3;
                  
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    return o;
                }

                uniform sampler2D _Udon_VideoTex;
                float4 _Udon_VideoTex_TexelSize;
                float4 _Udon_VideoTex_ST;
                float4x4 _Udon_VideoData;

                fixed4 frag(v2f i) : SV_Target{

                    // If vulume bar not enabled do not render pixel
					if (_Volume != 1.0){
                        discard;
                    }

                    i.uv.x = 1.0 - i.uv.x;
                    i.uv.y *= _Height;
                    i.uv.y -= 0.012;
                    i.uv.x *= _Width;
                    float xShift = .48 + (_Width - 1);
                    i.uv.x -= xShift;
                    float xDif = 0.02;
                    if (i.uv.x >= (.5 + xDif) || i.uv.x <= (.5 - xDif)) {
                        discard;
                    }
					float vol = _Udon_VideoData._21;
                    //vol = 1.0;
                    vol *= _Height * .959;
                    float2 uvy = i.uv;
                    float dist = distance(float2(0.5, vol), uvy);
                    float circleSize = 0.013;
                    float lineLen = 0.005;
                    if ((abs(i.uv.x) > (.5 + lineLen) || abs(i.uv.x) < (.5 - lineLen))) {
                        if (dist >= circleSize) {
                            discard;
                        }
                        if (abs(i.uv.y  - vol) >= circleSize) {
                            discard;
                        }
                    } else if (i.uv.y <= vol && dist > circleSize){
                        return float4(0.1, 0.7, 0.1, _Color.a);
                    }

                    if (dist < circleSize) {
                        return float4(0.7, 0.0, 0.1, _Color.a);
                    }

                    return float4(.3, 0.3, 0.3, _Color.a);

                }
                ENDCG
            }

        }
}
