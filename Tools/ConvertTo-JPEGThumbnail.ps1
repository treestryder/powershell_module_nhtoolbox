function ConvertTo-JPEGThumbnail {
    <#
    .Synopsis
       Converts an image (BMP, GIF, EXIF, JPG, PNG and TIFF) to a JPG image that has been cropped square and scaled.
    
    .EXAMPLE
    [byte[]]$photo = ConvertTo-JPEGThumbnail -Path $path
    $photo | Set-Content -Path out.jpg -Encoding Byte
    Set-ADUser -Identity identity -Replace @{ thumbnailPhoto = $photo }
    
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $Path,
        [int]$Pixels = 96
    )

    [void][reflection.assembly]::LoadWithPartialName("System.Drawing")

    # Handle FileInfo and String input.
    if ($Path -is [System.IO.FileInfo]) { $Path = $Path.FullName }
    
    try {
        Write-Verbose "Reading, cropping and scaling: $Path"
        $original = New-Object System.Drawing.Bitmap -ArgumentList $Path -ErrorAction Stop

        $smallestSidePixels = $original.Width
        if ($smallestSidePixels -gt $original.Height) {
            $smallestSidePixels = $original.Height
        }
        [int]$X1 = ($original.Width - $smallestSidePixels) / 2
        [int]$Y1 = ($original.Height - $smallestSidePixels) / 2
        
        $originalRectangle = New-Object System.Drawing.Rectangle -ArgumentList $X1, $Y1, $smallestSidePixels, $smallestSidePixels 
        $newBitmap = New-Object System.Drawing.Bitmap -ArgumentList $Pixels, $Pixels
        $newRectangle = New-Object System.Drawing.Rectangle -ArgumentList 0, 0, $newBitmap.Width, $newBitmap.Height
        $newGraphic = [System.Drawing.Graphics]::FromImage( $newBitmap )

<#
        DrawImage https://msdn.microsoft.com/en-us/library/ktyfbs10.aspx

To properly crop and resize, you need to apply the following settings to the graphics object:
        g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
        g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
        g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
        g.CompositingMode = CompositingMode.SourceOver;

Then you need to make an ImageAttributes instance to fix the border bug:

ImageAttributes ia = new ImageAttributes();
ia.SetWrapMode(WrapMode.TileFlipXY);
http://stackoverflow.com/a/8996947/80161

    Resize
    http://www.lewisroberts.com/2015/01/18/powershell-image-resize-function/
#>
        $newGraphic.DrawImage( $original, $newRectangle, $originalRectangle, [System.Drawing.GraphicsUnit]::Pixel )
        
        $ms = New-Object System.IO.MemoryStream
        $newBitmap.Save( $ms, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        Write-Output $ms.ToArray()
    }
    catch {
        throw
    }
    finally {
        $original.Dispose()
    }
}
