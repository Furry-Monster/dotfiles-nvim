-- Language and build provider are independent of the engine workflow.
-- Runtime directory, arguments, features and custom tasks come from project.json.
return { external = {}, runtime = { cwd = '.' } }
