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
[boolean]$DEBUG=$false

function Validate-ISBN ([string]$isbn_lookup){
	#Validate that the provided ISBN only contains digits and that it is an ISBN-10 or ISBN-13
	
	[boolean]$valid=$true
	
	#Some ISBNs contain an X as the last character
	if($($isbn_lookup | Select-String "^\d+X?$") -eq $null){
		Write-Error "ISBN contains illegal characters. HINT: Only enter numeric chars, no hyphens."
		$valid=$false
	}
	
	if(@(10,13) -NotContains "$isbn_lookup".Length){
		Write-Error "Provided ISBN is invalid length. ISBN should only be 10 or 13 char long."
		$valid=$false
	}
	
	return $valid
}

function Perform-Lookup ([string]$endpoint, [string]$isbn){
	#Perform a lookup based on an ISBN provided by the user. 
	#Then perform a secondary lookup for the author name based on isbn lookup results
	
	#First, fetch the data by ISBN
	"Looking up ISBN: ${endpoint}"
	
	Try{
		$book = (Invoke-WebRequest $endpoint.Replace("/API/LOOKUP","/isbn/$isbn")).Content | ConvertFrom-JSON
		$author_lookup = $book.authors.key
	}Catch{
		Write-Error "Error occurred when looking up ${isbn}: $_" -ErrorAction Stop
	}
	
	#Manual throttle between requests
	Start-Sleep -Seconds 2
	
	if ($author_lookup -ne $null){ 
		#Second, fetch the author info
		"Looking up Author: ${author_lookup}"
		Try{
			$author = (Invoke-WebRequest $endpoint.Replace("/API/LOOKUP","$author_lookup")).Content | ConvertFrom-JSON
		}Catch{
			Write-Error "Error occurred when looking up ${author_lookup}: $_" -ErrorAction Stop
		}
	} 
	
	#Last, build an object to return to the caller
	$book_info = @{
		"isbn" = $isbn
		"title" = $book.title;
		"full_title" = $book.full_title;
		"author" = $author.name -Join ", ";
		"revision" = $book.revision;
		"publishers" = $book.publishers -Join ", ";
		"publish_date" = $book.publish_date;
		"genre" = $book.subjects -Join ", ";
	}
	
	#if debug flag is enabled, print this object to Out-GridView
	if($DEBUG){ $book_info | Out-GridView -Title "$isbn - Fetched Results" }
	
	return $book_info
}

function Generate-Record ($l){
	#Create CSV record and write to output file
	#CSV record has following format "isbn|isbn10or13|title|full_title|author|revision#|publishers|publish_date|genres"
	
	return `
	($l.isbn).ToString() + "|" + `
	($l.isbn).ToString().Length + "|" + `
	$l.title + "|" + `
	$l.full_title + "|" + `
	$l.author + "|" + `
	$l.revision + "|" + `
	$l.publishers + "|" + `
	$l.publish_date + "|" + `
	$l.genre
	
}

function WriteTo-File ([string]$payload, [string]$filename){
	#Write payload to output file
	
	"$payload" | Add-Content $filename
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