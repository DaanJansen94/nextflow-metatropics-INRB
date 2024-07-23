process METAMAPS_CLASSIFY {
    tag "$meta.id"
    label 'process_high'

    container "$projectDir/images/metamaps.sif"
    conda "bioconda::metamaps=0.1.98102e9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metamaps:0.1.98102e9--h176a8bc_0':
        'daanjansen94/metamaps:v0.1' }"

    input:
    tuple val(meta), path(input), path(metamap), path(unmapped), path(parametersmeta)

    output:
    tuple val(meta), path("*_results.EM"), emit: classem
    tuple val(meta), path("*.EM.reads2Taxon.krona"), emit: classkrona
    tuple val(meta), path("*.EM.lengthAndIdentitiesPerMappingUnit"), emit: classlength
    tuple val(meta), path("*.EM.WIMP"), emit: classWIMP
    tuple val(meta), path("*.EM.contigCoverage"), emit: classcov

    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
      """
    metamaps classify --mappings ${prefix}_classification_results $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metamaps_classify: \$(echo \$(metamaps --help) | grep MetaMaps | perl -p -e 's/MetaMaps v |Simul.+//g' )
    END_VERSIONS
    """
}
