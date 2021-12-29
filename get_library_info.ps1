#get-lib-info.ps1

<#
	Author: Eric C. Grasby
	This script utilizes the OpenLibrary ISBN API to lookup and return information about a book in your collection.
	It contains some basic validations on ISBN (See Validate-ISBN) to try and make each request, to the API, genuine.
#>

[System.Guid]$GUID = New-Guid
$GUID = $GUID.guid
$ENDPOINT="https://openlibrary.org/API/LOOKUP.json"
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
	
	#First, fetch the data by ISBN
	"Looking up ISBN: ${endpoint}"
	
	Try{
		$book = (Invoke-WebRequest $endpoint.REPLACE("/API/LOOKUP","/isbn/$isbn")).Content | ConvertFrom-JSON
		$author_lookup = $book.authors.key
	}Catch{
		Write-Output "Error occurred when looking up ${isbn}:"
		Write-Output "$_"
	}
	
	#Manual throttle between requests
	Start-Sleep -Seconds 2
	
	if ($author_lookup -ne $null){ 
		#Second, fetch the author info
		"Looking up Author: ${author_lookup}"
		Try{
			
			$author = (Invoke-WebRequest $endpoint.REPLACE("/API/LOOKUP","$author_lookup")).Content | ConvertFrom-JSON
			$author = $author.name
		}Catch{
			Write-Output "Error occurred when looking up ${author_lookup}:"
			Write-Output "$_"
		}
	} 
	
	#Last, build an object to return to the caller
	return @{
		"book_info" = $book;
		"author_info" = $author;
	}
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
	if (! $(Validate-ISBN $isbn_lookup)){ continue }
	$isbn10or13 = $isbn_lookup.Length
	
	#API lookup with ISBN; convert payload to JSON
	$lib_info = Perform-Lookup $ENDPOINT $isbn_lookup
	if ($lib_info -eq $null){ throw "Error retrieving data" }
	$l = $lib_info
	
	#Create CSV record and write to output file
	#CSV record has following format "isbn|isbn10or13|title|full_title|author|publishers|publish_date|subjects"
	Write-Output "Writing out contents.."
	Write-Output $l
	$output_record = `
	$isbn_lookup + "|" + `
	$isbn10or13 + "|" + `
	$l["book_info"].title + "|" + `
	$l["book_info"].full_title + "|" + `
	$l["author_info"].author + "|" + `
	$l["book_info"].publishers + "|" + `
	$l["book_info"].publish_date + "|" + `
	$l["book_info"].subjects
	
	WriteTo-File $output_record $OUTPUT_FILE
	
}