#-----------------------------------------------------------------------
# Laravel Color Scheme for Multitail (Revised HTTP Path Regex)
#-----------------------------------------------------------------------
colorscheme:laravel

cs_re_s:green:^[^ ]* *[0-9]* *[^ ]* ([^ ]*)

# Timestamps: e.g., [2023-10-27 10:00:00]
cs_re_s:green:(^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\])

# Environment: e.g., local.INFO, production.ERROR
cs_re_s:red:^\s*\[\d{4}-\d{2}-\d{2}[^\]]+\]\s*([a-zA-Z0-9_-]+)\.

# --- Log Levels ---
cs_re_s:red:(\.(CRITICAL|ALERT|EMERGENCY):)
cs_re_s:red:(\.ERROR:)
cs_re_s:yellow:(\.WARNING:)
cs_re_s:blue:(\.INFO:)
cs_re_s:cyan:(\.NOTICE:)
cs_re_s:magenta:(\.DEBUG:)

# HTTP Methods, Paths, and Status Codes
cs_re_s:yellow:(\b(GET|POST|PUT|DELETE|PATCH|OPTIONS|HEAD)\b)
# Revised HTTP Path:
# This tries to match either a full URL's path or a simple path.
# It first looks for a full URL and captures the path part.
# If not, it tries to match a simple path. This might need two rules.

# Let's try two separate rules for paths: one for full URLs, one for relative paths.
# Rule 1: Path from a full URL (e.g., http://domain.com/path/to/resource)
# We capture the path part after the domain.
cs_re_s:cyan:(\s+https?:\/\/[^/\s]+(/[^?\s]*)) # Captures group 2: /path/to/resource
# Rule 2: Simple relative path (e.g., /path/to/resource)
cs_re_s:cyan:(\s+/[^?\s]*) # Captures the whole path like /path/to/resource

# HTTP Status Codes
cs_re_s:green:(\s[12]\d{2}\b)
cs_re_s:yellow:(\s[34]\d{2}\b)
cs_re_s:red:(\s5\d{2}\b)

# Exception Names
cs_re_s:red:([A-Za-z0-9_\\]+[Ee]xception)

# SQL Queries
cs_re_s:blue,,bold::(\b([Ss][Ee][Ll][Ee][Cc][Tt]|[Ii][Nn][Ss][Ee][Rr][Tt]\s+[Ii][Nn][Tt][Oo]|[Uu][Pp][Dd][Aa][Tt][Ee]|[Dd][Ee][Ll][Ee][Tt][Ee]\s+[Ff][Rr][Oo][Mm]|[Cc][Rr][Ee][Aa][Tt][Ee]\s+[Tt][Aa][Bb][Ll][Ee]|[Aa][Ll][Tt][Ee][Rr]\s+[Tt][Aa][Bb][Ll][Ee]|[Dd][Rr][Oo][Pp]\s+[Tt][Aa][Bb][Ll][Ee]|[Tt][Rr][Uu][Nn][Cc][Aa][Tt][Ee])\b)
cs_re_s:magenta,,bold::(\b([Ff][Rr][Oo][Mm]|[Ww][Hh][Ee][Rr][Ee]|[Ss][Ee][Tt]|[Vv][Aa][Ll][Uu][Ee][Ss]|[Jj][Oo][Ii][Nn]|[Ll][Ee][Ff][Tt]\s+[Jj][Oo][Ii][Nn]|[Rr][Ii][Gg][Hh][Tt]\s+[Jj][Oo][Ii][Nn]|[Ii][Nn][Nn][Ee][Rr]\s+[Jj][Oo][Ii][Nn]|[Oo][Nn]|[Gg][Rr][Oo][Uu][Pp]\s+[Bb][Yy]|[Oo][Rr][Dd][Ee][Rr]\s+[Bb][Yy]|[Ll][Ii][Mm][Ii][Tt]|[Oo][Ff][Ff][Ss][Ee][Tt]|[Aa][Nn][Dd]|[Oo][Rr]|[Nn][Oo][Tt])\b)

# Numbers
cs_re_s:green:(\b\d+(\.\d+)?(ms)?\b)

# Quoted strings
cs_re_s:cyan:("[^"]*")
cs_re_s:yellow:('[^']*')

# Stack trace lines
cs_re_s:yellow:(^#\d+\s+)

# Simplified stack trace file path regex as well, just in case (?:...) was an issue there too
cs_re_s:yellow:((/[A-Za-z0-9_.-]+)+/[A-Za-z0-9_.-]+\.[phprecinc]{2,5}) # File path
cs_re_s:green:(:\d+\)?) # Line number

cs_re:yellow:^Stack trace:.*

# Specific keywords
cs_re:yellow:deprecated
cs_re:red:failed|failure
cs_re:green:success|successful|completed|authenticated

# UUIDs or similar long hex strings
cs_re_s:cyan:(\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b)
cs_re_s:cyan:(\b[0-9a-fA-F]{20,}\b)

# --- End of Laravel Color Scheme ---
