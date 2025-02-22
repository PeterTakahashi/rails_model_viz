module RailsModelViz
  class GraphController < ActionController::Base
    def index
      Rails.application.eager_load!

      @mode = params[:mode] || 'relations'
      models = ApplicationRecord.descendants

      # Generate text for Mermaid's ER diagram
      @mermaid_text = build_mermaid_text(models, @mode)
    end

    private

    def build_mermaid_text(models, mode)
      graph_data = build_graph_data(models, mode)
      to_mermaid_er_diagram(graph_data)
    end

    def build_graph_data(models, mode)
      # For erDiagram, we assemble the list of columns each model has
      # and information about their associations
      nodes = []
      edges = []

      models.each do |model|
        # Retrieve columns only when mode=='columns' to include details
        columns = []
        if mode == 'columns'
          model.load_schema
          columns = model.columns.map { |col| [col.name, col.type.to_s] }
        end

        # Node (table) information
        nodes << {
          id: model.name,   # e.g., "User"
          columns: columns  # e.g., [ ["id","integer"], ["name","string"], ... ]
        }

        # Gather associations as edges
        model.reflect_on_all_associations.each do |assoc|
          # Polymorphic associations do not have a single definite class,
          # so we treat them separately
          if assoc.polymorphic?
            edges << { from: model.name, to: "Polymorphic(#{assoc.name})", type: assoc.macro.to_s }
          else
            edges << { from: model.name, to: assoc.klass.name, type: assoc.macro.to_s }
          end
        end
      end

      { nodes: nodes, edges: edges }
    end

    # ===========================================================================
    # Build a Mermaid erDiagram notation string
    # https://mermaid.js.org/syntax/entityRelationshipDiagram.html
    #
    #   erDiagram
    #     TABLE_NAME {
    #       column_name data_type
    #       column_name data_type
    #     }
    #
    #     TABLE_NAME ||--|{ OTHER_TABLE : "relationship"
    # ===========================================================================
    def to_mermaid_er_diagram(graph_data)
      mermaid = "erDiagram\n"

      # (1) Define each table (entity)
      graph_data[:nodes].each do |node|
        mermaid << "  #{node[:id]} {\n"

        # Output field definitions only if node[:columns] is present
        node[:columns].each do |(col_name, col_type)|
          # For example: "id integer", "name string", etc.
          mermaid << "    #{col_name} #{col_type}\n"
        end

        mermaid << "  }\n\n"
      end

      # (2) Define relationships
      #    ER notation like "||--||" indicates multiplicity (1, n, etc.)
      graph_data[:edges].each do |edge|
        from = edge[:from]
        to   = edge[:to]
        rel_type = edge[:type]  # e.g. "has_many", "belongs_to"

        # Convert association type to an ER diagram multiplicity symbol
        cardinality = map_assoc_to_er_cardinality(rel_type)

        # Example: User ||--|{ Post : "has_many"
        mermaid << "  #{from} #{cardinality} #{to} : \"#{rel_type}\"\n"
      end

      mermaid
    end

    # Map association types to ER diagram cardinality symbols:
    #  - belongs_to → 1-to-many from the other side, often "||--|{"
    #  - has_many   → 1-to-many
    #  - has_one    → 1-to-1
    #  - has_and_belongs_to_many → many-to-many
    def map_assoc_to_er_cardinality(rel_type)
      case rel_type.to_s
      when "belongs_to"
        "||--|{"
      when "has_many"
        "||--|{"
      when "has_one"
        "||--||"
      when "has_and_belongs_to_many"
        "}o--o{"
      else
        "||--||"  # Default to 1-to-1
      end
    end
  end
end
