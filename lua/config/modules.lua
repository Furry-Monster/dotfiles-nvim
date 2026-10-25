-- Add modules here; shared infrastructure does not depend on individual languages.
return {
    languages = { 'cpp', 'rust', 'csharp', 'lua', 'shader', 'auxiliary' },
    builders = { 'cmake', 'cargo', 'commands' },
    workflows = { 'default', 'engine', 'kernel', 'unity' },
}
