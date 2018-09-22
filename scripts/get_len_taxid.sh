#!/bin/bash
# Number of attempts to request data from e-utils
att=10

retrieve_nucleotide_fasta_xml()
{
	echo "$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=nuccore&id=${1}")"
}

for ACC in $1
do
	xml_out=""
	taxid=""
	# Try to retrieve information
	for i in $(seq 1 ${att});
	do
		xml_out="$(retrieve_nucleotide_fasta_xml "${ACC}")"
		taxid="$(echo "$xml_out" | awk -F '[<>]' '/Name="TaxId"/{print $3}'|head -1)"
		# If taxid was found, break
		if [[ ! -z "${taxid}" ]]; then break; fi;
	done
	# If taxid was not found, add to the error list and continue
	if [[ -z "${taxid}" ]];
	then
		error="${error} ${ACC}"
		continue
	fi
	# Extract sequence length
	len="$(echo "$xml_out" | awk -F '[<>]' '/Name="Length"/{print $3}'|head -1)"

	# Print output to STDOUT
	echo ${ACC}$'\t'${len}$'\t'${taxid}
done

# Print errors to STDERR
if [ ! -z "${error}" ]
then
	(>&2 echo "Failed to retrieve information: "${error})
	exit 1
fi
exit 0
