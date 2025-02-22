RailsModelViz::Engine.routes.draw do
  root to: "graph#index"
  resources :graph, only: [:index]
end
