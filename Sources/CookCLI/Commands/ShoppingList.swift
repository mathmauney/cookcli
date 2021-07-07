//
//  File.swift
//  
//
//  Created by Alexey Dubovskoy on 23/06/2021.
//

import Foundation
import ArgumentParser
import CookInSwift
import Catalog

extension Cook {

    struct ShoppingList: ParsableCommand {

        @Option(name: .shortAndLong, help:
                    """
                    Specify an aisle.conf file to set grouping. Cook automatically checks current directory in ./config/aisle.conf and $HOME/.config/cook/aisle.conf
                    """)
        var aisle: String?

        @Option(name: .shortAndLong, help:
                    """
                    Specify an inflection.conf file to define rules of pluralisation. Cook automatically checks current directory in ./config/inflection.conf and $HOME/.config/cook/inflection.conf
                    """)
        var inflection: String?


        @Argument(help: "File or directory with .cook files to include to shopping list")
        var filesOrDirectory: [String]

        @Option(help: "Set the output format to json or yaml")
        var outputFormat: OutputFormat = .text

        @Flag(help: "Print only the ingredients section of the output")
        var onlyIngredients = false

        // MARK: ParsableCommand
        static var configuration: CommandConfiguration = CommandConfiguration(abstract: "Create a shopping list")

        func run() throws {
            var aisleConfig: CookConfig?
            let aisleConfigPath = findConfigFile(type: "aisle", aisle)

            if let path = aisleConfigPath {
                if let text = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
//                    TODO add throw
                    let parser = ConfigParser(text)
                    aisleConfig = parser.parse()
                    print("HELPME Error loading config file at \(path), please check syntax", to: &errStream)
                } else {
                    print("HELPME Can't read aisle config file at \(path). Please check permissions", to: &errStream)

                    throw ExitCode.failure
                }
            }

            var inflectionConfig: CookConfig?
            let inflectionConfigPath = findConfigFile(type: "inflection", aisle)

            if let path = inflectionConfigPath {
                if let text = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
//                    TODO add throw
                    let parser = ConfigParser(text)
                    inflectionConfig = parser.parse()
                    print("HELPME Error loading config file at \(path), please check syntax", to: &errStream)
                } else {
                    print("HELPME Can't read inflection config file at \(path). Please check permissions", to: &errStream)


                    throw ExitCode.failure
                }
            }

            guard let files = try? listCookFiles(filesOrDirectory) else {
                print("HELPME Error getting .cook files from \(filesOrDirectory), please check file exists and permissions", to: &errStream)

                throw ExitCode.failure
            }

            do {
                let ingredientTable = try combineShoppingList(files, inflection: inflectionConfig)

                try ingredientTable.print(onlyIngredients: onlyIngredients, outputFormat: outputFormat, aisle: aisleConfig)

            } catch {
                print(error, to: &errStream)

                throw ExitCode.failure
            }
        }
    }
}
