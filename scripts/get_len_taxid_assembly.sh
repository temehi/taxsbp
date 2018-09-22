#!/bin/bash
# Number of attempts to request data from e-utils
att=10

retrieve_assembly_uid_xml()
{
	echo "$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=assembly&term=${1}")"
}

retrieve_assembly_accession_xml()
{
	echo "$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=assembly&id=${1}")"
}
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

for ACC in $1
do
	xml_out=""
	assembly_uid=""
	assembly_accession=""
	len_taxid="$("${SCRIPTPATH}"/get_len_taxid.sh "${ACC}" 2> /dev/null)"
	if [ $? -ne 0 ]; #If successfuly retrieve len and taxid
	then
		error="${error} ${ACC}"
		continue
	else
		for i in $(seq 1 ${att});
		do
			xml_out="$(retrieve_assembly_uid_xml "${ACC}")"
			assembly_uid="$(echo "$xml_out" | awk -F '[<>]' '/<Id>/{print $3}'|head -1)"
			# If assembly_uid was not found, try again
			if [[ -z "${assembly_uid}" ]]; then continue; fi;

			xml_out="$(retrieve_assembly_accession_xml "${assembly_uid}")"
			assembly_accession="$(echo "$xml_out" |  awk -F '[<>]' '/<AssemblyAccession>/{print $3}'|head -1)"
			# If taxid was found, break
			if [[ -z "${assembly_accession}" ]]; then continue; fi;
		done

		# If not found, add to the error list and continue
		if [[ -z "${assembly_accession}" ]];
		then
			error="${error} ${ACC}"
			continue
		fi

		# Print output to STDOUT (replacing space for tabs)
		echo "${len_taxid}"$'\t'${assembly_accession}
	fi
done

# Print errors to STDERR
if [ ! -z "${error}" ]
then
	(>&2 echo "Failed to retrieve information: "${error})
	exit 1
fi
exit 0