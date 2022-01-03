#get-lib-info.ps1

<#
	Author: Eric C. Grasby
	This script utilizes the OpenLibrary ISBN API to lookup and return information about a book in your collection.
	It contains some basic validations on ISBN (See Validate-ISBN) to try and make each request, to the API, genuine.
#>

[System.Guid]$GUID = New-Guid
$GUID = $GUID.guid
$ENDPOINT="https://openlibrary.org/API/LOOKUP.json"
$OUTPUT_FILE="$PSSCRIPTROOT\lookups_$GUID.csv"
[boolean]$DEBUG=$false

#try to source in the dependent functions first and error out if they cannot be imported
Try {
	. $PSSCRIPTROOT\resoruces\libfunctions.ps1
}
Catch{
	Write-Error "Error sourcing in lib functions! $_" -ErrorAction Stop
}

#loop forever until user runs CTL-C
while ($true){
	
	#get ISBN from user and validate
	$isbn_lookup = Read-Host -Prompt "Enter a valid ISBN. (CTRL-C to quit)"
	if (! $(Validate-ISBN $isbn_lookup)){ Continue }
	
	#API lookup with ISBN; convert payload to JSON
	$lib_info = Perform-Lookup $ENDPOINT $isbn_lookup
	if ($lib_info -eq $null){ throw "Error retrieving data" }
	
	#create and write output data
	$output_record = Generate-Record $lib_info
	WriteTo-File $output_record $OUTPUT_FILE
	
}