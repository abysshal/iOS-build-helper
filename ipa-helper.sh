#!/bin/bash

#Set up logging
logfile="/tmp/ipaHelper.log"
echo "========================================
$(date) - $0 $@
----------------------------------------" >> "$logfile"
exec 2> >(tee -a "$logfile" >&2) 1> >(tee -a "$logfile")

function close_log
{
logtext="$(cat $logfile)"
while [ "$(echo "$logtext" | grep "=====" -c)" -gt 49 ]; do
    logtext="${logtext#*========================================$'\n'}"
done
echo "========================================
$logtext" > $logfile
}

#take the name of the process as $1 (eg: "unzipping file" or "resiging app"), if there was an error, exit the script with the text "Error $1"
function check_status
{
if [ $? -ne 0 ]; then
    problem_encountered "Error $1"
fi
}

#if $ipa is "" then theres a problem, exit. if $1 is passed in, it is another possible required item (instead of the ipa file)
function assert_ipa
{
if [ "$ipa" = "" ];then
	message="missing app file"
	if [ "$1" != "" ];then
		message="$message or $1"
	fi
    problem_encountered "$message"
fi
}

#returns ipa file name in the working directory
function ipa_in_wd
{
cd "$wd"
find ./ -type f -maxdepth 1 -iname "*.ipa" | while read f; do
	f="${f:3}"
	echo "$f"
	return
done
}

#called to end the script with success
function script_done
{
clean_up
close_log
exit 0
}

#called to end script in error
function problem_encountered
{
if [ "$1" != "" ];then
	echo "$1" >&2
fi
echo 'type "help" for usage page' >&2
clean_up
close_log
exit 1
}

#display usage information

##Help Functions##
function help_help
{
echo '*****HELP*****

ipaHelper help [ -v ] [ commands... ]

Displays usage information for the different commands.

If -v option is present it shows the usage information for all of the commands.
'

echo "Commands:   Profile   Find   Info   Summary   Clean   Rezip   Verify   Resign   Open  Help"
echo
}

function help_clean
{
echo '*****CLEAN*****

ipaHelper clean [ file | --all ]

Cleans temporary files left over from previous command with the --dont-clean option.
If run with the --all option, the entire temp folder for ipaHelper is deleted.
If file is supplied, the temporary folder associated with that file is deleted.
'
}

function help_rezip
{
echo '*****REZIP*****

ipaHelper rezip outputfile

Rezips left over temporary files from Summary command with the --dont-clean option as outputfile.

Outputfile must be an app, ipa, appex, or zip file.
'
}

function help_profile
{
echo '*****PROFILE*****

ipaHelper profile [ file ] [ options ]

Checks the profile of an ipa, app, xcarchive, or zip file containing an app file, or shows the information about a mobileprovision file

If no file is provided, the first (alphabetically) ipa file in the working directory is used.

If no options are present, a summary of the provisioning profile is displayed.

Options:

[-v | --verbose] display the entire profile in xml format

[-e | --entitlements] display the entitlements on the profile
'
}

function help_find
{
echo '*****FIND*****

ipaHelper find [file] [options]

Looks for profiles saved in the users library matching the bundle ID of the ipa, app, xcarchive or zip file containing an app file.

If no file is provided, the first (alphabetically) ipa file in the working directory is used.

Options:

[-m | --matching] takes a pattern as an argument, only displays profiles matching this pattern.

[-n | --no-wildcard] only shows profiles with exact matches to the bundle ID, and not matching wildcard profiles.

[-a | --all] displays all profiles in the library.  Ignores --no-wildcard option.

[--json] returns the profile information in a JSON dictionary.
'
}

function help_info
{
echo '*****INFO*****

ipaHelper info [ file ] [ options ]

Checks the Info.plist of an ipa, app, xcarchive, or zip file containing an app file, or shows the information about an Info.plist file

If no file is provided, the first (alphabetically) ipa file in the working directory is used.

If no options are present, a summary of the Info.plist is displayed.

Options:

[-e | --edit] takes an editor as an argument and edits the Info.plist in this editor.  Uses default $EDITOR if no editor provided.

[-v | --verbose] display the entire Info.plist in xml format
'
}

function help_summary
{
echo '*****SUMMARY*****

ipaHelper summary [ file ] [ options ]

Displays profile and info.plist information about an ipa, app, xcarchive, or zip file containing an app file.

If no file is provided the first (alphabetically) ipa file in the working directory is used.

Options:

[--json] returns the summary information in a JSON dictionary.  Also adds the a key "AppDirectory" for the temporary unzipped app.

[-dc | --dont-clean] does not remove the temporary app directory after returning summary information
'
}

function help_verify
{
echo '*****VERIFY*****

ipaHelper verify [ file ]

Checks to make sure the necessary code signing components are in place for an ipa, app, xcarchive, or zip file containing an app file

If no file is provided the first (alphabetically) ipa file in the working directory is used.
'
}

function help_resign
{
echo '*****RESIGN*****

ipaHelper resign [ file ] [ options ]

Removes the code signature from an ipa, app, xcarchive, appex, or zip file containing an app file, and replaces it either with the first profile (alphabetically) in the directory with the file.

Resigns the file using the certificate on the profile, zips the resigned ipa file with the name [filename]-resigned.[filetype]. Zips as the same filetype as the input file by default, except that xcarchive files are resigned as app files.

If no file is provided, the first (alphabetically) ipa file in the working directory is used.

Options:

[-p | --profile] takes a specific profile as an argument, uses this profile for resigning the ipa

[-f | --find] looks for a profile in the users library matching the ipas bundle ID

[-m | --matching] takes patterns as arguments.  restricts the find command to profiles matching the patterns.

[-o | --output ] takes an output file as an argument, zips the resigned ipa file using this name instead of [ipa filename]-resigned.ipa

[-d | --double-check] displays information about the file, its Info.plist, and the provisioning profile and offers a choice to continue or quit

[-F | --force] will overwrite output file on resign without asking.  Uses the profiles App ID if the App ID and Bundle ID do not match.
'
}

function help_open
{
echo '*****OPEN*****

ipaHelper open [file]

Copies file into a temporary file location, unzipped and prints the path to the app file.

If no file is provided, the first (alphabetically) ipa file in the working directory is used.
'
}

function clean_up
{
if [ "$opt_dont_clean" = "" -a "$file_id" != "" -o "$cmd" = "clean" ]; then
    if [ -d "/tmp/ipa_helper/$file_id" ]; then
        rm -rf "/tmp/ipa_helper/$file_id"
    fi
fi
}

##Parsing Functions##

#takes a string ($1) and returns a value for the key (passed in a $2)
function value_for_key
{
tmp="${1##*<key>"$2"</key>}"
if [ "$1" = "$tmp" ]; then
    return
fi
tmp="${tmp%%</*}"
tmp="${tmp##*>}"
echo "$tmp"
}

#returns useful information from an Info.plist
function parse_info
{
echo "       CFBundleName: $(value_for_key "$1" "CFBundleName")"
echo "CFBundleDisplayName: $(value_for_key "$1" "CFBundleDisplayName")"
echo " CFBundleIdentifier: $(value_for_key "$1" "CFBundleIdentifier")"
echo "    CFBundleVersion: $(value_for_key "$1" "CFBundleVersion")"
echo " ShortBundleVersion: $(value_for_key "$1" "CFBundleShortVersionString")"
echo " Minimum OS Version: $(value_for_key "$1" "MinimumOSVersion")"

iPhone=$(echo "$1" | grep -i "UIDeviceFamily" -A 4 | grep "integer>1" >/dev/null && echo "iPhone")
iPad=$(echo "$1" | grep -i "UIDeviceFamily" -A 4 | grep "integer>2" >/dev/null && echo "iPad")

if [ "$iPhone" != "" -a "$iPad" != "" ]; then
    echo "  Supported Devices: "$iPhone", "$iPad""
elif [ "$iPhone" != "" ]; then
    echo "  Supported Devices: "$iPhone""
else
    echo "  Supported Devices: "$iPad""
fi
}

#returns useful information from a profile
function display_profile
{
if [ ! -f "$1" ]; then
    echo "       Profile Name: No embedded profile"
    return
fi
fullprofile="$(parse_profile "$1")"
echo "$fullprofile" | awk '{split($0,a,"|"); print "       Profile Name: "a[2]; print "     App Identifier: "a[1]; print "          Team Name: "a[4];  print "       Profile Type: "a[5];  print "    Expiration Date: "a[6]; print "               UUID: "a[3]; }'
}

# $1 is what is grepped. $2 is a new line delimited list of required matches
function grep_loop
{
result="$1"
while read search; do
    result="$(echo "$result" | grep -i "$search")"
done <<< "$2"
echo "$result"
}

function library_profiles
{
find ~/Library/MobileDevice/"Provisioning Profiles" -iname "*.mobileprovision" | while read profile; do
    echo "$(parse_profile "$profile")"
done
}

#return first profile matching bundle ID $1 and criteria $2
function first_library_match
{
library="$(find ~/Library/MobileDevice/"Provisioning Profiles" -iname "*.mobileprovision")"
while read profile; do
    fullprofile="$(parse_profile "$profile")"
    result="$(profiles_direct_match "$fullprofile" "$1")"
    if [ "$result" != "" ]; then
        result="$(grep_loop "$result" "$2")"
    fi
    if [ "$result" != "" ]; then
        echo "$result"
        break
    fi
done <<< "$library"
if [ "$result" = "" ]; then
    while read profile; do
        fullprofile="$(parse_profile "$profile")"
        result="$(profiles_wildcard_match "$fullprofile" "$1")"
        if [ "$result" != "" ]; then
            result="$(grep_loop "$result" "$2")"
        fi
        if [ "$result" != "" ]; then
            echo "$result"
            break
        fi
    done <<< "$library"
fi
}

function parse_profile
{
fullprofile="$(security cms -D -i "$1")"
echo "$fullprofile" | grep 'application-identifier\|<key>Name</key>\|UUID' -A 1 | grep 'string' | awk '{split($0,a,"</?string>"); print a[2]}' | tr '\n' '|'
team="$(echo -n "$fullprofile" | grep 'TeamName' -A 1 | grep 'string' | awk '{split($0,a,"</?string>"); print a[2]}' | tr -d '\n')"
echo -n "${team}|"
echo -n "$(profile_type "$fullprofile")|"
expiration="$(echo -n "$fullprofile" | grep 'ExpirationDate' -A 1 | grep 'date' | awk '{split($0,a,"</?date>"); print a[2]}')"
echo -n "$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expiration" +"%b %e, %Y")|"
echo "$1"
}

function profile_type
{
type="$(echo "$1" | grep "task" -A 1 | tail -1)"
if [ "${type#*<}" = "true/>" ]; then
    echo -n "Development"
else
    if [ "$(echo "$1" | grep "ProvisionedDevices")" != "" ]; then
        echo -n "Adhoc Distribution"
    elif [ "$(echo "$1" | grep "ProvisionsAllDevices")" != "" ]; then
        echo -n "Universal Distribution"
    else
        echo -n "App Store Distribution"
    fi
fi
}

# $1 is the profile list, $2 is the bundle ID to match
function profiles_direct_match
{
echo "$1" | while read profile; do
    tmp="${profile%%|*}"
    tmp="${tmp#*.}"
    if [ "$2" = "$tmp" ]; then
        echo "$profile"
    fi
done
}

# $1 is the profile list, $2 is the bundle ID to match
function profiles_wildcard_match
{
wildcards="$(wildcard_profiles "$1")"
echo "$wildcards" | while read profile; do
    tmp="${profile%%|*}"
    tmp="${tmp#*.}"
    if [[ "$2" = "${tmp%?}"* ]]; then
        echo "$profile"
    fi
done
}

# returns wildcard profiles in $1
function wildcard_profiles
{
echo "$1" | while read profile; do
    tmp="${profile%%|*}"
    if [ "${tmp: -1}" = "*" ]; then
        echo "$profile"
    fi
done
}

#converts profiles ($1) to JSON
function profiles_to_JSON
{
echo '{"profiles":['
echo "$1" | awk '{split($0,a,"|"); print "{\"Profile\":\""a[2]"\",\"App ID\":\""a[1]"\",\"Team\":\""a[4]"\",\"Type\":\""a[5]"\",\"Expires\":\""a[6]"\",\"UUID\":\""a[3]"\",\"File\":\""a[7]"\"}"}'
echo "]}"
}

#converts profiles ($1) to human readable format
function profiles_to_readable
{
echo "$1" | awk '{split($0,a,"|"); print "***** PROFILE *****"; print "Profile:"a[2]; print " App ID:"a[1]; print "   Team:"a[4];  print "   Type:"a[5];  print "Expires:"a[6]; print "   UUID:"a[3]; print "   File:"a[7]; }'
}

#returns profile name from a list of resign args
function profile_from_args {
if [ "$opt_profile" != "" ]; then
    echo "$opt_profile"
	return
fi
cd "$bd"
find ./ -type f -maxdepth 1 -iname "*.mobileprovision" | while read f; do
        f="${f:3}"
        echo "$bd/$f"
        break
done
}

#returns output filename from a list of resign args
function output_from_args
{
if [ "$opt_output" != "" ]; then
    echo "$opt_output"
    return
fi
echo "$bd/${ipa%.*}-resigned.$filetype"
}

# $1 is the file, $2 is the editor
function edit_file_with
{
if [ "$2" != "" -a "$1" != "" ]; then
    "$2" "$1"
    check_status "editing file"
fi
}

function convert_to_JSON
{
echo -n "{"
while read line; do
    if [ "${line:0:1}" != "*" ]; then
        while [ "${line:0:1}" = " " ]; do
            line="${line:1}"
        done
        echo -n '"'
        echo -n "${line//: /":"}"
        echo -n '",'
    fi
done <<< "$1"
echo -n '"'
echo -n 'AppDirectory":"'
echo -n "$ad"
echo -n '",'
}


#Make Entitlements.plist - $1 is the full profile text
function make_entitlements_from_profile
{
echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
echo '<plist version="1.0">'
echo '<dict>'
tmp="${1##*Entitlements</key>}"
tmp="${tmp#*<dict>}"
tmp="${tmp%%</dict>*}"
echo "$tmp"
echo '</dict>'
echo '</plist>'
}

### CMD FUNCTIONS ###
function cmd_help
{
if [ "$1" = "" ]; then
    help_help
elif [ "$1" = "-v" ]; then
    help_profile
    help_find
    help_info
    help_summary
    help_clean
    help_rezip
    help_verify
    help_resign
    help_open
else
    while [ "$1" != "" ]; do
        case "$1" in
            [cC]lean )      help_clean;;
            [rR]ezip )      help_rezip;;
            [hH]elp* )      help_help;;
            [pP]rofile* )   help_profile;;
            [fF]ind* )      help_find;;
            [iI]nfo* )      help_info;;
            [sS]ummary* )   help_summary;;
            [vV]erify* )    help_verify;;
            [rR]esign* )    help_resign;;
            [oO]pen )       help_open;;
            * ) problem_encountered "Not a valid command";;
        esac
        shift
    done
fi
}

function cmd_profile
{
	fullprofile="$(security cms -D -i "$profile")"
	if [ "$opt_verbose" = "Y" ]; then
        echo "$fullprofile"
    elif [ "$opt_entitlements" = "Y" ]; then
        tmp="${fullprofile##*Entitlements}"
        tmp="${tmp#*<dict>}"
        tmp="${tmp%%</dict>*}"
        tmp="${tmp//?[[:space:]]</<}"
        tmp="${tmp:1}"
        echo '***************ENTITLEMENTS***************'
        echo "$tmp"
        echo '******************************************'
    else
        echo '*********************************************************'
        display_profile "$profile"
        echo '*********************************************************'
    fi
}

function cmd_info
{
    if [ "$opt_edit" != "" ]; then
        xml=Y
        #check to see if the info.plist is a binary
        plist="$(cat $infoplist)"
        if [ "${plist:0:5}" != "<?xml" ]; then
            xml=N
            plutil -convert xml1 "$infoplist"
        fi
        edit_file_with "$infoplist" "$opt_edit"
        #convert back to binary if it was binary
        if [ "$xml" = "N" ]; then
            plutil -convert binary1 "$infoplist"
        fi
        if [ "$ipa" != "" ]; then
            cmd_rezip "$bd/$ipa"
        fi
    else
        cp "$infoplist" "/tmp/ipa_helper/$file_id/Info.plist"
	    infoplist="/tmp/ipa_helper/$file_id/Info.plist"
	    plutil -convert xml1 "$infoplist"
	    infoplist="$(cat "$infoplist")"
        if [ "$opt_verbose" = "Y" ]; then
            echo "$infoplist"
        else
            echo '*********************************************************'
            parse_info "$infoplist"
            echo '*********************************************************'
        fi
    fi
}

function cmd_summary
{
    if [ "$ipa" != "" ]; then
        cp "$ad/Info.plist" "/tmp/ipa_helper/$file_id/Info.plist"
        plutil -convert xml1 "/tmp/ipa_helper/$file_id/Info.plist"
        info="$(cat "/tmp/ipa_helper/$file_id/Info.plist")"
        profile="$ad/embedded.mobileprovision"
    else
        ipa="$(basename "$profile")"
    fi
    filesize="$(du -sh "$bd/$ipa" | cut -f 1)"
    filesize="${filesize/M/ MB}"
    filesize="${filesize/K/ KB}"
    echo '********************************************************************'
    echo "               File: $ipa"
    echo "           Filesize: $filesize"
    if [ "$info" != "" ]; then
        parse_info "$info"
    fi
    codesignature="$(cmd_verify 2>&1 | awk '{split($0,a,": "); print a[2]}' | tr '\n' ',' | sed 's/,/, /g')"
    codesignature="${codesignature%??}"
    if [ "$codesignature" != "" ]; then
        echo "     Code Signature: $codesignature"
    fi
    display_profile "$profile"
    echo '********************************************************************'
}

function cmd_find
{
if [ "$opt_all" = "" ]; then
    cp "$ad/Info.plist" "/tmp/ipa_helper/$file_id/Info.plist"
    plutil -convert xml1 "/tmp/ipa_helper/$file_id/Info.plist"
    info="$(cat "/tmp/ipa_helper/$file_id/Info.plist")"
    bundleid="$(value_for_key "$info" "CFBundleIdentifier")"
fi
library="$(library_profiles)"
if [ "$opt_matching" != "" ]; then
    library="$(grep_loop "$library" "$opt_matching")"
fi
if [ "$opt_all" = "" ]; then
    profiles="$(profiles_direct_match "$library" "$bundleid")"
    if [ "$opt_no_wildcard" != "Y" ]; then
        if [ "$profiles" != "" ]; then
            profiles="$profiles
            $(profiles_wildcard_match "$library" "$bundleid")"
        else
            profiles="$(profiles_wildcard_match "$library" "$bundleid")"
        fi
    fi
    if [ "$profiles" = "" ]; then
        echo "No matching profiles"
        script_done
    fi
else
    profiles="$library"
fi
if [ "$opt_json" = "json" ]; then
    profiles_to_JSON "$profiles"
else
    profiles_to_readable "$profiles"
fi
}

function cmd_verify
{
	cd "$(dirname "$ad")"
	base="$(basename "${ad}")"
	codesign --verify --no-strict -vvvv "$base"
}

function cmd_resign
{
    cd "$bd"
	cp "$ad/Info.plist" "/tmp/ipa_helper/$file_id/Info.plist"
    plutil -convert xml1 "/tmp/ipa_helper/$file_id/Info.plist"
    infoplist="$(cat "/tmp/ipa_helper/$file_id/Info.plist")"
	bundleid="$(value_for_key "$infoplist" CFBundleIdentifier)"
    profile=
    if [ "$opt_find" = "Y" ]; then
        profile="$(first_library_match "$bundleid" "$opt_matching")"
        profile="${profile##*|}"
    else
    	profile="$(profile_from_args "$@")"
    fi
    if [ "$profile" = "" ];then
		problem_encountered "No Provisioning profile"
	fi
	fullprofile="$(security cms -D -i "$profile")"
	cert="$(value_for_key "$fullprofile" TeamName)"
	appid="$(value_for_key "$fullprofile" application-identifier)"
	entitlementsstring="--entitlements /tmp/ipa_helper/$file_id/Entitlements.plist"
    tent="$(make_entitlements_from_profile "$fullprofile")"
    echo "$tent" > /tmp/ipa_helper/$file_id/Entitlements.plist
    #check to see if there was an output file
    newipa="$(output_from_args "$@")"
    newfiletype="${newipa##*.}"
    if [ "$newfiletype" != "ipa" -a "$newfiletype" != "app" -a "$newfiletype" != "zip"  -a "$newfiletype" != "xcarchive" -a "$newfiletype" != "appex" ]; then
        problem_encountered "Invalid output type"
    fi

    if [ "$filetype" = "appex" -a "$newfiletype" != "appex" ]; then
        problem_encountered "App extensions can only be resigned as app extensions"
    fi

    #see if this output file already exists
    if [ -f "$newipa" -a "$opt_force" != "Y" ]; then
        echo "$(basename "$newipa") already exists."
        input=
        while [ "$input" != "o" ]; do
            case "$input" in
                [cC]* ) echo ""
                        script_done;;
                [oO]* ) break;;
                * )     echo -n "Overwrite (o) or Cancel (c)? "
                        read -n 1 input;;
            esac
        done
        echo ""
    fi
	if [ "$opt_dont_clean" = "Y" ];then
        echo '*************************IPA File*************************'
        echo "          input file: $ipa"
        echo "         output file: $(basename "$newipa")"
        echo '************************Info.plist************************'
        parse_info "$infoplist"
        echo '*************************Profile**************************'
        display_profile "$profile"
        echo '**********************************************************'
        input=
		while [ "$input" != "y" ];do
			case "$input" in
				[n] )   echo ""
                        script_done;;
				[y] )   break;;
				* )	echo -n 'Continue with resign? (y or n):'
					read -n 1 input;;
			esac
		done
        echo ""
	fi
    #make sure AppID and CFBundleID match
	bundlestring=
    matching=N
    trimmedappid="${appid#*.}"
    #see if the app id is a match to the bundle id
    if [ "$trimmedappid" = "$bundleid" ]; then
        matching=Y
    fi
    #if the app id is a wildcard, see if the pattern matches the bundleid
    if [[ ("${appid: -1}" = "*") && ("$bundleid" = "${trimmedappid%?}"*) ]]; then
        matching=Y
    fi
	if [ "$matching" = "N" ]; then
        newbundleID=
        if [ "$opt_force" = "Y" ]; then
            if [ "${trimmedappid: -1}" = "*" ]; then
                trimmedappid="${trimmedappid%?}"
                if [ "${trimmedappid: -1}" = "." ]; then
                    newbundleID="${trimmedappid}${bundleid##*.}"
                else
                    match="${trimmedappid##*.}"
                    if [ "${bundleid##*$match}" != "$bundleid" ]; then
                        newbundleID="${trimmedappid}${bundleid##*$match}"
                    else
                        newbundleID="${trimmedappid}.${bundleid##*.}"
                    fi
                fi
            else
                newbundleID="$trimmedappid"
            fi
        else
		    echo '**********************************************************'
		    echo "The profile's App ID: $appid and the"
		    echo "file's Bundle ID: $bundleid do not match."
		    echo '**********************************************************'
            input=
            while [ "$input" != "y" ]; do
                case "$input" in
                    [nN]* ) echo ""
                            script_done;;
                    [yY]* ) break;;
                    * )     echo -n "Continue with resign? (y or n):"
                            read -n 1 input;;
                esac
            done
            echo ""
            while [ "$newbundleID" = "" ]; do
                echo -n "sign with bundleID:"
                read newbundleID
            done
        fi
        xml=Y
		#check to see if the info.plist is a binary
		plist="$(cat "$ad/Info.plist")"
		if [ "${plist:0:5}" != "<?xml" ]; then
			xml=N
			plutil -convert xml1 "$ad/Info.plist"
		fi
	    tmp="${infoplist#*<key>CFBundleIdentifier</key>}"
		tmp="${tmp#*</}"
		tbck="</$tmp"
		tmp="${infoplist%$tbck}"
		tmp="${tmp%>*}"
		tfrt="$tmp>"
		bundlestring="-i ${appid#*.}"
		echo "$tfrt$newbundleID$tbck" > "$ad/Info.plist"
		if [ "$xml" = "N" ]; then
			plutil -convert binary1 "$ad/Info.plist"
		fi
	fi
    rm -rf "$ad/_CodeSignature/" "$ad/ResourceRules.plist" 1>&3 2>&4
	cp "$profile" "$ad/embedded.mobileprovision"
    if [ -d "$ad/Frameworks/" ]; then
        codesign -f -s "$cert" "$ad/Frameworks/"* 1>&3 2>&4
        check_status "signing frameworks"
    fi
    codesign -f -s "$cert" $entitlementsstring $bundlestring "$ad" 1>&3 2>&4
    check_status "resigning the app"
    cmd_rezip "$newipa"
    echo "Resign Successful"
}

#take the .ipa_payload folder in the tmp directory and zip/copy it to file $1
function cmd_rezip
{
filetype="${1##*.}"
newfile="$1"
if [ "$filetype" = "xcarchive" ]; then
    newfile="${1%.*}.app"
    filetype="app"
elif [ "$filetype" != "ipa" -a "$filetype" != "app" -a "$filetype" != "zip" -a "$filetype" != "appex" ]; then
    problem_encountered "Invalid file type"
fi
if [ ! -d /tmp/ipa_helper/"$file_id" ]; then
    problem_encountered "Nothing to zip"
fi
if [ "$filetype" = "ipa" ]; then
    cd "/tmp/ipa_helper/$file_id"
    zip -qr "$newfile" Payload/ 1>&3 2>&4
    check_status "zipping the ipa file"
elif [ "$filetype" = "zip" ]; then
    cd "/tmp/ipa_helper/$file_id/Payload"
    zip -qr "$newfile" *.app/ 1>&3 2>&4
    check_status "zipping the zip file"
elif [ "$filetype" = "app" ]; then
    cp -r /tmp/ipa_helper/"$file_id"/Payload/*.app/ "$newfile"
    check_status "coping the app file"
elif [ "$filetype" = "appex" ]; then
    cp -r /tmp/ipa_helper/"$file_id"/Payload/*.appex/ "$newfile"
    check_status "coping the appex file"
fi
}

#### MAIN ####

bd="$(pwd)"

#first arg should be the command ($cmd)
case "$1" in
    h | help )  cmd="help";;
    p | prof | profile )    cmd="profile";;
    i | info )  cmd="info";;
    f |find )   cmd="find";;
    s | summary )   cmd="summary";;
    v | verify )    cmd="verify";;
    r | resign )    cmd="resign";;
    z | rezip ) cmd="rezip";;
    c | clean ) cmd="clean";;
    o | open )  cmd="open";;
    -* | "" )   problem_encountered "missing command";;
    *)          problem_encountered "invalid command";;
esac

shift

#if cmd was "help" or "h" show the usage page
if [ "$cmd" = "help" ];then
    cmd_help "$@"
    script_done
fi

# get ipa/profile/info.plist/directory for the following commands that need one of these.

#if the first arg is an ipa/app/zip/xcarchive file, use the ipas directory as the basedirectory ($bd) and the ipa as the ($ipa)
#if the first arg is a path, use that path as the bd, otherwise use the working directory as the bd
#if the first arg is a mobileprovision file, use that file as the profile ($profile) and the profiles directory as the bd
#if the first arg is an Info.plist file, use that file as the $(infoplist) and the Info.plists directory as the bd
#otherwise use the first ipa file (alphabetically) in the bd as the ipa.
wd="$(pwd)"
ipa=
filetype=
profile=
infoplist=
if [ "${1%.ipa}" != "$1" -o "${1%.app*}" != "$1" -o "${1%.xcarchive*}" != "$1"  -o "${1%.zip*}" != "$1" -o "${1%.appex*}" != "$1" ];then
    bd="$(dirname "${1}")"
	ipa="$(basename "${1}")"
	shift
	cd "$bd"
	bd="$(pwd)"
elif [ "${1%.mobileprovision}" != "$1" ];then
	bd="$(dirname "${1}")"
    profile="$(basename "${1}")"
    shift
    cd "$bd"
    bd=$(pwd)
	profile="$bd/$profile"
elif [ "${1%Info.plist}" != "$1" ];then
	bd="$(dirname "${1}")"
    infoplist="$(basename "${1}")"
    shift
    cd "$bd"
    bd="$(pwd)"
	infoplist="$bd/$infoplist"
elif [ "${1: -1}" = "/" ];then
	cd "$1"
	bd="$(pwd)"
	shift
    ipa="$(ipa_in_wd)"
elif [ "${1:0:1}" = "-" -o "$1" = "" ]; then
    ipa="$(ipa_in_wd)"
else
    problem_encountered "invalid filetype"
fi

#### OPTIONS ####

opt_verbose=
opt_entitlements=
opt_matching=
opt_no_wildcard=
opt_all=
opt_json=
opt_edit=
opt_dont_clean=
opt_profile=
opt_find=
opt_output=
opt_double_check=
opt_force=

while [ "$1" != "" ]; do
    case "$1" in
        -v | --verbose )        opt_verbose=Y;;
        -dc | --dont-clean )    opt_dont_clean=Y;;
        -e | --entitlements )   if [ "$cmd" = "profile" ]; then
                                    opt_entitlements=Y
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        -m | --matching )       if [ "$cmd" = "find" -o "$cmd" = "resign" ]; then
                                    while  [ "$2" != "" -a "${2:0:1}" != "-" ]; do
                                        if [ "$opt_matching" != "" ]; then
                                            opt_matching="$opt_matching"$'\n'
                                        fi
                                        opt_matching="$opt_matching$2"
                                        shift
                                    done
                                    if [ "$opt_matching" = "" ]; then
                                        problem_encountered "missing pattern for matching argument"
                                    fi
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        -n | --no-wildcard )    if [ "$cmd" = "find" ]; then
                                    opt_no_wildcard=Y
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        -a | --all )            if [ "$cmd" = "find" -o "$cmd" = "clean" ]; then
                                    opt_all=Y
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        --json )                if [ "$cmd" = "find" -o "$cmd" = "summary" ]; then
                                    opt_json=Y
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        --edit )                if [ "$cmd" = "info" ]; then
                                    if  [ "$2" != "" -a "${2:0:1}" != "-" ]; then
                                        opt_edit="$2"
                                        shift
                                    else
                                        if [ "$EDITOR" = "" ]; then
                                            opt_edit="vim"
                                        else
                                            opt_edit="$EDITOR"
                                        fi
                                    fi
                                fi;;
        -p | --profile )        if [ "$cmd" = "resign" ]; then
                                    if [ "$2" != "" -a "${2:0:1}" != "-" ]; then
				        	            cd "$wd"
				        	            tmp="$2"
				        	            if [[ "$2" = *"/"* ]]; then
					    	                cd "$(dirname "$2")"
					    	                tmp="$(basename "$2")"
    				    	            fi
    					                dir="$(pwd)"
    				    	            opt_profile="$dir/$tmp"
                                        shift
                                    else
                                        problem_encountered "missing profile for profile argument"
                                    fi
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        --find )                if [ "$cmd" = "resign" ]; then
                                    opt_find=Y
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        -o | --output )         if [ "$cmd" = "resign" ]; then
                                    if [ "$2" != "" -a "${2:0:1}" != "-" ]; then
                                        cd "$wd"
                                        tmp="$2"
                                        if [[ "$2" = *"/"* ]]; then
                                            cd "$(dirname "${2}")"
                                            tmp="$(basename "${2}")"
                                        fi
                                        dir="$(pwd)"
                                        opt_output="$dir/$tmp"
                                        shift
                                    else
                                        problem_encountered "missing profile for output argument"
                                    fi
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        -d | --double-check )   if [ "$cmd" = "resign" ]; then
                                    opt_double_check=Y
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        -F | --force )          if [ "$cmd" = "resign" ]; then
                                    opt_force=Y
                                else
                                    problem_encountered "invalid argument: $1"
                                fi;;
        *)  problem_encountered "invalid argument: $1";;
    esac
    shift
done

if [ "$opt_verbose" = "Y" ]; then
    exec 3>&1 4>&2
else
    exec 3>>$logfile 4>>$logfile
fi

if [ "$cmd" = "clean" ]; then
    if [ "$opt_all" = "Y" ]; then
        file_id=""
    else
        assert_ipa "--all option"
        file_id="$(echo "$bd" | grep "/tmp/ipa_helper/" | sed 's/.*tmp\/ipa_helper\/\([0-9A-F\-]*\).*/\1/')"
        if [ "$file_id" = "" ]; then
            cmd=  #Set cmd to empty to avoid a full clean here
            problem_encountered "$bd/$ipa not in an ipaHelper temporary folder and cannot be cleaned"
        fi
    fi
    script_done
fi

filetype="${ipa##*.}"

#make ad folder
cd "$bd"

file_id="$(uuidgen)"
while [ -d  "/tmp/ipa_helper/$file_id" ]; do
    file_id="$(uuidgen)"
done


ad=
if [ "$filetype" = "xcarchive" ]; then
    mkdir -p "/tmp/ipa_helper/$file_id/Payload"
    cd "$ipa"
    tmp="$(find ./ -iname "*.app*" -maxdepth 3 -mindepth 3)"
    cd "$bd"
    tmpd="$ipa$(dirname "${tmp:2}")/"
    tmpa="$(basename "${tmp}")"
    cp -r "$tmpd$tmpa" "/tmp/ipa_helper/$file_id/Payload/$tmpa/" 1>&3 2>&4
    check_status "accessing app file in xcarchive"
    ad="/tmp/ipa_helper/$file_id/Payload/$tmpa"
elif [ "$filetype" = "app" -o "$filetype" = "appex" ]; then
    mkdir -p "/tmp/ipa_helper/$file_id/Payload"
    cp -r "$ipa" "/tmp/ipa_helper/$file_id/Payload/$ipa/"
    ad="/tmp/ipa_helper/$file_id/Payload/$ipa"
elif [ "$filetype" = "ipa" ]; then
    mkdir -p "/tmp/ipa_helper/$file_id"
    unzip -q "$ipa" -d "/tmp/ipa_helper/$file_id" 1>&3 2>&4
    check_status "unzipping ipa file"
    if [ ! -d "/tmp/ipa_helper/$file_id/Payload" ];then
        problem_encountered "problem unzipping ipa folder"
    fi
    cd "/tmp/ipa_helper/$file_id/Payload"
    app="$(find ./ -type d -maxdepth 1 -iname "*.app*")"
    ad="/tmp/ipa_helper/$file_id/Payload/${app:3}"
elif [ "$filetype" = "zip" ]; then
    mkdir -p "/tmp/ipa_helper/$file_id"
    unzip -q "$ipa" -d "/tmp/ipa_helper/$file_id/Payload" 1>&3 2>&4
    check_status "unzipping ipa file"
    if [ ! -d "/tmp/ipa_helper/$file_id/Payload" ];then
        problem_encountered "problem unzipping ipa folder"
    fi
    cd "/tmp/ipa_helper/$file_id/Payload"
    app="$(find ./ -type d -iname "*.app*")"
    app="$(echo "$app" | while read -r line; do if [ "$line" = "${line%.dSYM}" ]; then echo "$line"; break; fi; done)"
    if [ "$app" = "" ]; then
        problem_encountered "zip file does not contain app file"
    fi
    ad="/tmp/ipa_helper/$file_id/Payload/${app:3}"
fi

#echo "ipa: $ipa ad: $ad"
#script_done

## COMMANDS THAT MAY NEED AN IPA##

#profile command
if [ "$cmd" = "profile" ];then
	#if the first arg wasn't a profile, then an ipa file is necessary
	if [ "$profile" = "" ];then
		assert_ipa mobileprovision
		profile="$ad/embedded.mobileprovision"
	fi
    cmd_profile "$@"
    script_done
fi

#Info.plist command
if [ "$cmd" = "info" ];then
	if [ "$infoplist" = "" ];then
		assert_ipa Info.plist
        infoplist="$ad/Info.plist"
    fi
    cmd_info "$@"
    script_done
fi

#find command, to find profiles in library matching the app's bundle ID
if [ "$cmd" = "find" ]; then
    if [ "$opt_all" = "" ]; then
        assert_ipa "--all option"
    fi
    cmd_find "$@"
    script_done
fi

#summary command, to show info.plist and profile information in brief summary
if [ "$cmd" = "summary" ]; then
    if [ "$profile" = "" ]; then
        assert_ipa mobileprovision
    fi
    summary="$(cmd_summary)"
    if [ "$opt_json" = "Y" ]; then
        summary="$(convert_to_JSON "$summary")"
        summary="${summary%,}}"
    fi
    echo "$summary"
    script_done
fi

## COMMANDS THAT NEED AN IPA
assert_ipa

#verify command, to see if an ipa is signed
if [ "$cmd" = "verify" ]; then
	cmd_verify "$@"
    script_done
fi

#resign command, to resign an ipa
if [ "$cmd" = "resign" ];then
    cmd_resign "$@"
    script_done
fi

#rezip command, to zip up uncleaned files into an ipa file
if [ "$cmd" = "rezip" ]; then
    cmd_rezip "$bd/$ipa"
    script_done
fi

#open command, to open the ipa file, print out the app directory and not clean
if [ "$cmd" = "open" ]; then
    echo "$ad"
    opt_dont_clean=Y
    script_done
fi
