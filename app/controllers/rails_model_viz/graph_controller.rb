module RailsModelViz
  class GraphController < ActionController::Base
    def index
      Rails.application.eager_load!

      @mode = params[:mode] || 'relations'
      models = ApplicationRecord.descendants

      @mermaid_text = build_mermaid_text(models, @mode)
    end

    private

    def build_mermaid_text(models, mode)
      graph_data = build_graph_data(models, mode)
      to_mermaid_er_diagram(graph_data)
    end

    def build_graph_data(models, mode)
      nodes = []
      edges = Set.new  # Use a Set to avoid duplicates

      models.each do |model|
        sanitized_model_name = sanitize_model_name(model.name)

        # Get columns if mode == 'columns'
        columns = []
        if mode == 'columns'
          model.load_schema
          columns = model.columns.map { |col| [col.name, col.type.to_s] }
        end

        # Node info
        nodes << {
          id: sanitized_model_name,  # e.g. "User" or "PaperTrail_Version"
          columns: columns
        }

        # Build edges for each association
        model.reflect_on_all_associations.each do |assoc|
          from_name = sanitized_model_name
          to_class  = assoc.polymorphic? ? "Polymorphic(#{assoc.name})" : assoc.klass.name
          to_name   = sanitize_model_name(to_class)
          rel_type  = assoc.macro.to_s  # "has_many", "belongs_to", etc.

          # OPTIONAL: Skip self-referencing if not desired
          # next if from_name == to_name

          # Build a unique key so we don't add duplicates
          edge_key = [from_name, to_name, rel_type]
          unless edges.include?(edge_key)
            edges << edge_key
          end
        end
      end

      { nodes: nodes, edges: edges.to_a }  # convert Set back to an Array for rendering
    end

    # ------------------------------------------------------
    # Convert our graph data into Mermaid 'erDiagram' format
    # ------------------------------------------------------
    def to_mermaid_er_diagram(graph_data)
      mermaid = "erDiagram\n"

      # (1) Define each table (entity)
      graph_data[:nodes].each do |node|
        mermaid << "  #{node[:id]} {\n"
        node[:columns].each do |col_name, col_type|
          mermaid << "    #{col_name} #{col_type}\n"
        end
        mermaid << "  }\n\n"
      end

      # (2) Define relationships (edges)
      graph_data[:edges].each do |(from, to, rel_type)|
        cardinality = map_assoc_to_er_cardinality(rel_type)
        # Example: User ||--|{ Post : "has_many"
        mermaid << "  #{from} #{cardinality} #{to} : \"#{rel_type}\"\n"
      end

      mermaid
    end

    # ------------------------------------------------------
    # Map Rails association to Mermaid ER cardinality symbol
    # ------------------------------------------------------
    def map_assoc_to_er_cardinality(rel_type)
      case rel_type
      when "belongs_to"
        "||--|{"
      when "has_many"
        "||--|{"
      when "has_one"
        "||--||"
      when "has_and_belongs_to_many"
        "}o--o{"
      else
        "||--||"  # default to 1-to-1
      end
    end

    # ------------------------------------------------
    # Sanitize model/association names for Mermaid
    # Replace :: with _ to prevent syntax errors
    # ------------------------------------------------
    def sanitize_model_name(name)
      name.gsub("::", "_")
    end
  end
end
