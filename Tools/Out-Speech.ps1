function Out-Speech {
<#
.SYNOPSIS
    Converts strings to audible speech.
#>
    [CmdletBinding()]
    param (
        # String to be converted to speach.
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias('IO')]
        $InputObject,
        [switch]$Wait
    )
    
    begin {
        Add-Type -AssemblyName System.Speech
        $SpeechSynthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer 
    }
    
    process {
        if ($Wait) {
            $null = $SpeechSynthesizer.Speak(($InputObject | Out-String -Stream) )    
        }
        else {
            $null = $SpeechSynthesizer.SpeakAsync(($InputObject | Out-String -Stream) )
        }
        
    }
}
