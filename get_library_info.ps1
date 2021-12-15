#get-lib-info.ps1

<#
	Author: Eric C. Grasby
	This script utilizes the OpenLibrary ISBN API to lookup and return information about a book in your collection.
	It contains some basic validations on ISBN (See Validate-ISBN) to try and make each request, to the API, genuine.
#>

[System.Guid]$GUID = New-Guid
$GUID = $GUID.guid
$ENDPOINT="https://openlibrary.org/isbn/LOOKUP.json"
$OUTPUT_FILE="lookups_$GUID.csv"

function Validate-ISBN ([string]$isbn_lookup){
	[boolean]$valid=1
	
	if($($isbn_lookup | Select-String "^\d+$") -eq $null){
		Write-Error "ISBN contains illegal characters. HINT: Only enter numeric chars, no hyphens."
		$valid=0
	}elseif(@(10,13) -NotContains "$isbn_lookup".Length){
		Write-Error "Provided ISBN is invalid length. ISBN should only be 10 or 13 char long."
		$valid=0
	}
	
	return $valid
}

function Perform-Lookup ([string]$endpoint, [long]$isbn){
	"Looking up ${endpoint}"
	
	Try{
		$output = Invoke-WebRequest $endpoint
	}Catch{
		Write-Output "Error occurred when looking up ${isbn}:"
		Write-Output "$_"
	}
	
	return $output
}

function WriteTo-File ([string]$payload, [string]$filename){
	"$payload" | Add-Content $filename
}

"
##-----------------------##
    ISBN Lookup Utility`n
      CTL-C to quit.
##-----------------------##
"

#loop forever until user runs CTL-C
while ($true){
	
	#get ISBN from user and validate
	$isbn_lookup = Read-Host "Enter a valid ISBN"
	$isValid = Validate-ISBN $isbn_lookup
	if (! $isValid){ continue }
	
	#API lookup with ISBN; convert payload to JSON
	$lib_info = Perform-Lookup $ENDPOINT.Replace("LOOKUP",$isbn_lookup)
	if ($lib_info -eq $null){ throw "Error retrieving data" }
	$l = $lib_info.Content | ConvertFrom-JSON
	
	#Create CSV record and write to output file
	#CSV record has following format "isbn|title|full_title|publishers|publish_date|subjects"
	$output_record = `
	$isbn_lookup + "|" + `
	$l.title + "|" +`
	$l.full_title + "|" + `
	$l.publishers + "|" + `
	$l.publish_date + "|" + `
	$l.subjects
	
	WriteTo-File $output_record $OUTPUT_FILE
	
}