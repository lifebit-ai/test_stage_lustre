dir = params.vcf_dir ? params.vcf_dir : params.s3_dir

ch_files = Channel.create()
Channel.fromPath("${dir}/*${params.suffix}")
    .toSortedList()
    .subscribe onNext: { items ->
        items.each { ch_files << it }
    },
    onComplete: { ch_files.close() }

ch_files2 = ch_files.take(params.file_count)

if (params.vcf_header) {

process vcf_header {
    label 'bcftools'
    publishDir "${params.outdir}", mode: 'copy'

    input:
    file(ingvcf) from ch_files2

    output:
    file("${ingvcf.simpleName}.head.txt") into ch_header_files

    script:
    """
    ${params.before_cmd}
    bcftools view -h ${ingvcf} > ${ingvcf.simpleName}.head.txt
    ${params.after_cmd}
    """
}

} 


if (!params.vcf_header) {

process split_file {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    file(infiles) from ch_files2.buffer(size: params.in_n, remainder: true)

    output:
    file("${infiles[0]}.*") into ch_out_files

    script:
    """
    ${params.before_cmd}
    cat ${infiles} > combined
    split -n ${params.split_n} --suffix-length 3 --numeric-suffixes combined ${infiles[0]}.
    ${params.after_cmd}
    """
}

}
