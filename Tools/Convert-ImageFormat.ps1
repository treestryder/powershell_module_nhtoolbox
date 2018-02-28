<#
.Synopsis
    Converts an image file from one format into BMP, GIF, JPEG, PNG or TIFF format.
#>
function Convert-ImageFormat {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$OutPath,
        [Parameter(Mandatory=$true)]
		[ValidateSet('bmp','gif','jpeg','png','tiff')]
        [string]$Format
    )
	
	Add-Type -AssemblyName System.Drawing

	$imageFormat = switch($Format) {
		'bmp'  { [System.Drawing.Imaging.ImageFormat]::Bmp }
		'gif'  { [System.Drawing.Imaging.ImageFormat]::Gif }
		'jpeg' { [System.Drawing.Imaging.ImageFormat]::Jpeg }
		'png'  { [System.Drawing.Imaging.ImageFormat]::Png }
		'tiff' { [System.Drawing.Imaging.ImageFormat]::Tiff }
	}

	$bm = [System.Drawing.Bitmap]::FromFile($Path)
	$bm.Save($OutPath, $imageFormat)
	$bm.Dispose()
}