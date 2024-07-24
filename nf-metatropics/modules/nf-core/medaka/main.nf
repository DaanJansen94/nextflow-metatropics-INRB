process MEDAKA {
    tag "${meta.id}.${meta.virus}"
    label 'process_medium'
 
   conda "bioconda::medaka=1.4.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:1.4.4--py38h130def0_0' :
        'daanjansen94/medaka:v1.4.3' }"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.vcf"), optional: true, emit: assembly
    tuple val(meta), path("*.bam"), path("*.bai"), optional: true, emit: bamfiles
    path "versions.yml", emit: versions
    path "*.coverage.txt", optional: true, emit: coveragefiles

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.virus}"
    """
    if [ -s $assembly ] && [ \$(grep -c ">" $assembly) -gt 0 ]; then
        medaka_haploid_variant \\
            -t $task.cpus \\
            $args \\
            -i $reads \\
            -r $assembly \\
            -o ./
        if [ \$? -eq 0 ]; then
            mv medaka.annotated.vcf ${prefix}.vcf
            mv calls_to_ref.bam ${prefix}.sorted.bam
            mv calls_to_ref.bam.bai ${prefix}.sorted.bam.bai
            rm -f medaka.vcf
            samtools depth -a ${prefix}.sorted.bam > ${prefix}.sorted.bam.coverage.txt
            
            # Calculate genome coverage
            total_bases=\$(wc -l < ${prefix}.sorted.bam.coverage.txt)
            covered_bases=\$(awk '{if (\$3 > 0) count++} END {print count}' ${prefix}.sorted.bam.coverage.txt)
            coverage_percent=\$(awk "BEGIN {print (\$covered_bases / \$total_bases) * 100}")
            
            # Check if coverage is less than 20%
            if (( \$(echo "\$coverage_percent < 20" | bc -l) )); then
                echo "Coverage (\$coverage_percent%) is below 20%. Removing coverage file."
                rm ${prefix}.sorted.bam.coverage.txt
            else
                echo "Coverage: \$coverage_percent%"
            fi
        else
            echo "Medaka processing failed for ${prefix}. Creating empty output files." >&2
            touch ${prefix}.vcf
            touch ${prefix}.sorted.bam
            touch ${prefix}.sorted.bam.bai
        fi
    else
        echo "Assembly file is empty or contains no sequences for ${prefix}. Creating empty output files." >&2
        touch ${prefix}.vcf
        touch ${prefix}.sorted.bam
        touch ${prefix}.sorted.bam.bai
    fi
    # Remove empty files
    find . -type f -empty -delete
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
