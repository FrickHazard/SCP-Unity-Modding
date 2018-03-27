Shader "Unlit/SCP099Eye"
{
	Properties
	{
		[HideInInspector] _MainTex ("Texture", 2D) = "white" {}
		[HideInInspector] _EyeYScale("Default Eye Y scale", Range(0, 0.4)) = 0.211
		[HideInInspector] _EyeXScale("Eye X Scale", Range(0, 3.0)) = 1.19
	    _EyeLidTex("Eye Lid Texture", 2D) = "red" {}
		_EyeLidThickness("Eye Lid Thickness", Range(0, 0.5)) = 0.01
		_ScleraTex("Sclera Texture", 2D) = "white" {}
		_IrisTex("Iris Texture", 2D) = "black" {}
		_IrisColor("Color OF Iris", Color) = (1,1,1,1)
		_EyeIrisSize("Size of Iris", Range(0, 0.5)) = 0.01
		[HideInInspector]_Fade("Fade", Range(0, 1.0)) = 0
		[HideInInspector]_LookDirX("Iris X Look Coord", Range(0, 1)) = 0.5
		[HideInInspector]_LookDirY("Iris Y Look Coord", Range(0, 1)) = 0.5
		_LookMaxRadius("Max Look radius of Iris", Range(0, 1)) = 0.1
	}
	SubShader
	{
		// to be rendered after geometry
		Tags{ "Queue" = "Transparent" "RenderType" = "Opaque" }

		GrabPass{
			Name "BASE"
			Tags{ "LightMode" = "Always" }
		}

		Pass
		{
			Fog{ Mode Off }
			Name "BASE"
			Tags{ "LightMode" = "Always" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers nomrt
			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform sampler2D _EyeLidTex;
			uniform sampler2D _ScleraTex;
			uniform sampler2D _IrisTex;
			uniform float4 _MainTex_ST;
			uniform float _EyeLidThickness;
			uniform float _EyeIrisSize;
			uniform float _EyeXScale;
			uniform float _EyeYScale;
			uniform float _DistortBlendRadius;
			uniform float _Fade;
			uniform float _LookDirX;
			uniform float _LookDirY;
			uniform float _LookMaxRadius;
			uniform fixed4 _IrisColor;
			sampler2D _GrabTexture;
			float4 _GrabTexture_TexelSize;
			sampler2D_float _CameraDepthTexture;
			sampler2D _WorldNormalsForEyes;

			// sin curve function
			float sinCurve(float value, float xOffset, float yOffset, float xScale, float yScale)
			{
				return (yScale * sin(((value * xScale) - ((xOffset * xScale) + 1.5)) * 3.14)) + yOffset;
			}

			struct input
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct output
			{
				float4 uvgrab : TEXCOORD1;
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 screenUV : TEXCOORD3;
				float3 ray : TEXCOORD4;
				half3 orientation : TEXCOORD5;
				half3 orientationX : TEXCOORD6;
				half3 orientationZ : TEXCOORD7;
			};
			
			output vert (input v)
			{
				output o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvgrab = ComputeGrabScreenPos(o.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenUV = ComputeScreenPos(o.vertex);
				o.ray = UnityObjectToViewPos(float4(v.vertex.xyz, 1)).xyz * float3(-1, -1, 1);
				o.orientation = mul((float3x3)unity_ObjectToWorld, float3(0, 1, 0));
				o.orientationX = mul((float3x3)unity_ObjectToWorld, float3(1, 0, 0));
				o.orientationZ = mul((float3x3)unity_ObjectToWorld, float3(0, 0, 1));
				return o;
			}

			CBUFFER_START(UnityPerCamera2)
			// float4x4 _CameraToWorld;
			CBUFFER_END
			
			fixed4 frag (output o) : SV_Target
			{
				/****               Projection Of Eye On Surface      ****/
				// fake decal projection
				// divide by far plane
				half2 origin = half2(o.uv.xy);
				o.ray = o.ray * (_ProjectionParams.z / o.ray.z);
				float2 uv = o.screenUV.xy / o.screenUV.w;
				// read depth and reconstruct world position
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = Linear01Depth(depth);
				//vieport pos
				float4 vpos = float4(o.ray * depth,1);
				// world pos
				float3 wpos = mul(unity_CameraToWorld, vpos).xyz;
				// local object pos
				float3 opos = mul(unity_WorldToObject, float4(wpos,1)).xyz;

				// discard parts that arent visible / projected
				clip(float3(0.5,0.5,0.5) - abs(opos.xyz));

				// multiply the non projection-direction components of vector
				o.uv = opos.xy + 0.5;

				half3 normal = tex2D(_WorldNormalsForEyes, uv).rgb;
				fixed3 wnormal = normal.rgb * 2.0 - 1.0;
				// orientation is Direction of projection, 0.3 is minimum scale / clipping value
				clip(dot(wnormal, o.orientationZ) - 0.3);
				half2 diff = (origin - o.uv);
				
				/**  Grab Pass **/
				half2 offset = _GrabTexture_TexelSize.xy * diff;
                #ifdef UNITY_Z_0_FAR_FROM_CLIPSPACE //to handle recent standard asset package on older version of unity (before 5.5)
				o.uvgrab.xy = offset * UNITY_Z_0_FAR_FROM_CLIPSPACE(o.uvgrab.z) + o.uvgrab.xy;
                #else
				o.uvgrab.xy = offset * o.uvgrab.z + o.uvgrab.xy;
                #endif
				half4 background = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(o.uvgrab));
				half4 col = background;

				/***********          Drawing of Eye using Sin function         **********/
				fixed2 centerCoord = fixed2(0.5, 0.5);

				fixed isBlendPixel = 0;

				float sinWaveValue = sinCurve(o.uv.x, centerCoord.x, centerCoord.y, (_EyeXScale), _EyeYScale);

				float sinWaveValueNegative = sinCurve(o.uv.x, centerCoord.x, centerCoord.y, (_EyeXScale), - _EyeYScale);

				fixed alpha = 0;

				// sclera and iris
				if (o.uv.y > sinWaveValueNegative && o.uv.y < sinWaveValue) {
					half2 lookCenter = half2(centerCoord.x + (_LookDirX *_LookMaxRadius), centerCoord.y + (_LookDirY * _LookMaxRadius));
					if (distance(o.uv, lookCenter) < _EyeIrisSize) {
						// iris uvs based on iris thickness
						float2 irisCoords = float2((((o.uv.x - lookCenter.x) / _EyeIrisSize) / 2) + 0.5, (((o.uv.y - lookCenter.y) / _EyeIrisSize) / 2) + 0.5);

						col = col * (tex2D(_IrisTex, irisCoords) *_IrisColor);
					}
					else {
						// sclera uvs based on sclera lrngth
						float2 scleraCoords = float2((((o.uv.x - centerCoord.x) / (1.0 / _EyeXScale)) ) + 0.5, (((o.uv.y - centerCoord.y) / (1.0 / _EyeXScale)) ) + 0.5);
						col = col * tex2D(_ScleraTex, scleraCoords);
					}
				}
				else {
					// upper lid
					if (abs(o.uv.y - sinWaveValue) < _EyeLidThickness && o.uv.y > sinWaveValue) {
						if (o.uv.y + _EyeLidThickness > sinWaveValueNegative) {
							alpha = max((abs(o.uv.y - sinWaveValue) / _EyeLidThickness), alpha);
							isBlendPixel = 1;
						}
					}

					// lower lid
					if (abs(o.uv.y - sinWaveValueNegative) < _EyeLidThickness  && o.uv.y < sinWaveValueNegative) {
						if (o.uv.y - _EyeLidThickness < sinWaveValue) {
							alpha = max((abs(o.uv.y - sinWaveValueNegative) / _EyeLidThickness), alpha);
							isBlendPixel = 1;
						}
					}
				}

				// make sure x scale is in bounds of sin function
				if (isBlendPixel && o.uv.x < (centerCoord.x - ((1.0 / _EyeXScale) / 2)) - (_EyeLidThickness / 1.5)) {
					isBlendPixel = 0;
				}

				if (isBlendPixel && o.uv.x >(centerCoord.x + ((1.0 / _EyeXScale) / 2)) + (_EyeLidThickness / 1.5)) {
					isBlendPixel = 0;
				}

				// make edges of eyelids blend into distortion map
				if (isBlendPixel  == 1) {
					float edgeDistanceRight = abs(o.uv.x - ((centerCoord.x - ((1.0 / _EyeXScale) / 2)) - (_EyeLidThickness / 1.5)));
					float edgeDistanceLeft = abs(o.uv.x - ((centerCoord.x + ((1.0 / _EyeXScale) / 2)) + (_EyeLidThickness / 1.5)));
					if (edgeDistanceRight < (_EyeLidThickness) ) {
						alpha = max(alpha, 1 - (edgeDistanceRight / _EyeLidThickness));
					}
					if (edgeDistanceLeft < (_EyeLidThickness )) {
						alpha = max(alpha, 1 -(edgeDistanceLeft / _EyeLidThickness));
					}
					col = col * lerp(tex2D(_EyeLidTex, o.uv), fixed4(1, 1, 1, 1), (alpha));
				}

				col = lerp(col, background, _Fade);

				return col;
			}
			ENDCG
		}
	}
}
