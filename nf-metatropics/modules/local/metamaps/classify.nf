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
    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
    """
    metamaps classify --mappings ${prefix}_classification_results $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metamaps_classify: \$(echo \$(metamaps --help) | grep MetaMaps | perl -p -e 's/MetaMaps v |Simul.+//g' )
    END_VERSIONS
    """
}
