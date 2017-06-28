/*
Visualization of 1D Discrete Cosine Transform (DCT) basis image
* https://www.google.com/search?q=dct+basis+images&tbm=isch

Copyleft 2017
Michaelangel007
https://github.com/Michaelangel007/shadertoy_1d_dct_visualization

NOTE: If you use parts of this shader please add a comment link so other people can find it. Thanks.

References:
http://download.nvidia.com/developer/presentations/2005/GDC/OpenGL_Day/OpenGL_Image_Processing_Tricks.pdf

*/

#define PI 3.14159265359

float fft(vec2 uv)
{
    return cos( uv.y * PI * (2.0*uv.x + 1.0) / 16.0 );
}

float plot(vec2 st, float x, float w)
{
    return  smoothstep( x-w, x  , st.y) - 
            smoothstep( x  , x+w, st.y);
}

float plot1(vec2 st, float y)
{
    return plot( st, y, 0.01 );
}

float plot2(vec2 st, float y)
{
    return plot( st, y, 0.02 );
}

void mainImage( out vec4 fragColor, in vec2 st )
{
    // st - scaled:     x = 0 .. 799, y = 0 .. 449
    // uv - normalized: x = 0 ..   1, y = 0 ..   1
    // pq - transformed
	// ij - quantized
 
    vec2 cs = vec2( 64.0, 16.0 ); // cell sale
    vec2 uv = st / iResolution.xy;

/*
    Map 8x8 -> 64x8

From DCT basis image
    uv
    07 17 27 37 47 57 67 77
    06 16 26 36 46 56 66 76
    05 15 25 35 45 55 65 75
    04 14 24 34 44 54 64 74
^   03 13 23 33 43 53 63 73
|   02 12 22 32 42 52 62 72
|   01 11 21 31 41 51 61 71
y=0 00 10 20 30 40 50 60 70
    x=0 --->

To
    00 10 20 30 40 50 60 70 | ... | 07 17 27 37 47 57 67 77
    00 10 20 30 40 50 60 70 | ... | 07 17 27 37 47 57 67 77
    00 10 20 30 40 50 60 70 | ... | 07 17 27 37 47 57 67 77
    00 10 20 30 40 50 60 70 | ... | 07 17 27 37 47 57 67 77
    00 10 20 30 40 50 60 70 | ... | 07 17 27 37 47 57 67 77
    00 10 20 30 40 50 60 70 | ... | 07 17 27 37 47 57 67 77
    00 10 20 30 40 50 60 70 | ... | 07 17 27 37 47 57 67 77

     0  1  2  3  4  5  6  7 ... 56 57 58 59 60 61 62 63
    cx
*/
    vec2 ij = floor( uv * 8.0 ); // quantized 8x8 grid
    vec2 pq = vec2(
    	mod((uv.x * cs.x), 8.0 ),
    	ij.x
    );

    bool  bZoom   = (iMouse.z > 0.5);
    bool  bGrid   = (iMouse.y < 0.5*iResolution.y);
    bool  bLoRes  = iResolution.x < 900.0;
    bool  bFirst  = (ij.x < 1.0); // in first column?
    float iClickX = floor( 8.0 * iMouse.x / iResolution.x );
    
    vec3  color   = vec3( 0.0 );
    vec3  cDotOdd = vec3( 0.2, 1.0, 0.5 ); // Discrete   cos wave (green)
    vec3  cDotEvn = vec3( 1.0, 1.0, 0.0 ); //            cos wave (yellow)
    vec3  cWave   = vec3( 0.0, 0.5, 1.0 ); // Continuous cos wave (blue )
    vec3  cGrid   = vec3( 0.2, 0.6, 0.5 ); // vec3(0.254, 0.6578, 0.554)
    vec3  cEdge   = vec3( 1.0, 0.0, 0.0 ); // red
    vec3  cBack   = vec3( 0.1, 0.2, 0.3 ); // dark blue
    vec3  cGrey   = vec3( 0.2, 0.2, 0.2 );

    float EdgeW = 0.5; // 1.0 / iResolution.x; // 1 px edge between columns
    if( (uv.x > 0.1) && mod( st.x, iResolution.x / 8.0 ) <= 0.5 )
    {
        if( !bZoom || bGrid )
        {            
        	fragColor = vec4(cEdge,1.0);
        	return;
        }
    }

    float c = (1.0 + fft(        pq )) * 0.5; // Continuous
    float d = (1.0 + fft( floor( pq))) * 0.5; // Discrete
    
    if( bZoom )
    {
        if( ij.x != iClickX ) // Dim columns not selected
        {
            c *= 0.25;
            d *= 0.25;
        }
    }
    
    if( uv.y >= 0.75 ) // Top = Continuous
    {
 		   float y = c;
           color = vec3( y ); // TODO: Gamma correct
    }
    else
    if( uv.y >= 0.50 ) // Middle = Discrete
    {
          float y  = d;
          color = vec3( y ); // TODO: Gamma correct
    }
    else // Bottom = Continuous (blue) and Discrete (green/yellow)
    {
        // Discrete Wave
        float even2    = mod(   ij.x, 2.0 );
        float even8    = mod(   pq.x, 2.0 );
        float even64   = mod(2.*pq.x, 2.0 );
              color = bLoRes
                  ? cBack * ( even2 + 0.2*even64 ) + 0.5*cBack*(1.0 - even2)
                  : cBack * ( even2 + 0.5*even8 )
        		  ;  

        if( bZoom )
        {
			vec2 dz = vec2( ij.x, iClickX ); // 8.0 * uv; ij.x
            d = 0.5 + 0.5*fft( floor( dz ) );
            color = vec3( d );
        }        
        
        float y1      = plot2( uv,d*0.5 );
        vec3 cDot     = (even2 < 1.0) ? cDotEvn : cDotOdd;
    	      color   = mix( color, cDot, y1 );

        
        // Continuous Wave
        float freq    = bFirst ? 64.0 : 4.0*ij.x; // Technically u=0 freq=0.0 but 64 for better visualization
        float offset  = ij.x * PI;

        if( bZoom )
        {
            freq   = 0.5 * iClickX;
            offset = 0.0;
            if( iClickX == 0.0 )
                freq = 8.0; // Technically zero, but 8 for better visualization
        }
        
        float y2      = 0.5 + 0.5*cos( freq*uv.x * 2.0 * PI + offset );
        float x2      = plot( uv, y2*0.5, freq * 1.0/iResolution.x * (bZoom ? 4.0 : 2.0) );
              color   = mix( color, cWave, x2 );

        if( bGrid )
        { 
            /* */ vec2  gCells = bLoRes
                ? vec2(  8.0,  8.0 ) // number of grid height cells is doubled as we only show 1/2
                : vec2( 64.0, 20.0 )
                ;

            vec2 isGrid = mod( st, iResolution.xy / gCells );
            if( (isGrid.x < 1.0) || (isGrid.y < 1.0 ) )
                color = cGrid; // NOT += as grid always on top
        }
	}

    fragColor = vec4(color,1.0);
}
