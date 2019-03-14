package com.thelastpickle.tlpcluster.commands

import com.beust.jcommander.Parameter
import com.beust.jcommander.Parameters
import com.beust.jcommander.converters.FileConverter
import com.thelastpickle.tlpcluster.Context
import com.thelastpickle.tlpcluster.containers.CassandraBuildJava8
import java.io.File
import java.lang.Exception

class CassandraDirectoryNotFound : Exception()

@Parameters(commandDescription = "Create a custom named Cassandra build from a working directory.")
class BuildCassandra(val context: Context)  : ICommand {

    @Parameter(description = "Name of build", names = ["-n"])
    lateinit var name : String

    @Parameter(description = "Path to build", converter = FileConverter::class)
    lateinit var location : File

    override fun execute() {

        if(!location.exists()) {
            throw CassandraDirectoryNotFound()
        }

        context.createBuildSkeleton(name)

        val cassandraBuilder = CassandraBuildJava8(context)

        // create the container
        cassandraBuilder.buildContainer()
        println("Starting cassandra build process")
        
        cassandraBuilder.runBuild(location.absolutePath, name)
    }
}