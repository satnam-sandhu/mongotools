#!/bin/bash

# Function to print usage instructions
print_usage() {
    echo "Usage: $0 {mmv|mcp} <source_db/source_collection> <target_db/target_collection> [--host=<host>] [--port=<port>] [--username=<username>] [--password=<password>] [--uri=<connection_uri>]"
    exit 1
}

# Function to validate parameters
validate_params() {
    if [[ -z "$SOURCE_DB" || -z "$SOURCE_COLLECTION" || -z "$TARGET_DB" || -z "$TARGET_COLLECTION" ]]; then
        echo "Error: Missing required parameters."
        print_usage
    fi
}

# Function to construct the MongoDB connection string
construct_connection_string() {
    if [[ -n "$URI" ]]; then
        CONNECTION_STRING="$URI"
    else
        CONNECTION_STRING="mongodb://"

        if [[ -n "$USERNAME" && -n "$PASSWORD" ]]; then
            CONNECTION_STRING+="$USERNAME:$PASSWORD@"
        fi

        CONNECTION_STRING+="${HOST:-localhost}:${PORT:-27017}"
    fi
}

# Function to move a collection
mmv() {
    validate_params

    # Export the collection
    mongoexport --uri="$CONNECTION_STRING/$SOURCE_DB" --collection="$SOURCE_COLLECTION" --out="$SOURCE_COLLECTION.json" || {
        echo "Error: Failed to export collection $SOURCE_COLLECTION from database $SOURCE_DB."
        exit 1
    }

    # Import into the target database
    mongoimport --uri="$CONNECTION_STRING/$TARGET_DB" --collection="$TARGET_COLLECTION" --file="$SOURCE_COLLECTION.json" || {
        echo "Error: Failed to import collection $SOURCE_COLLECTION into $TARGET_DB as $TARGET_COLLECTION."
        exit 1
    }

    # Remove the source collection
    mongo --eval "db.getSiblingDB('$SOURCE_DB').$SOURCE_COLLECTION.drop()" --quiet || {
        echo "Error: Failed to drop the collection $SOURCE_COLLECTION from database $SOURCE_DB."
        exit 1
    }

    # Clean up
    rm -f "$SOURCE_COLLECTION.json"

    echo "Successfully moved $SOURCE_COLLECTION from $SOURCE_DB to $TARGET_COLLECTION in $TARGET_DB."
}

# Function to copy a collection
mcp() {
    validate_params

    # Export the collection
    mongoexport --uri="$CONNECTION_STRING/$SOURCE_DB" --collection="$SOURCE_COLLECTION" --out="$SOURCE_COLLECTION.json" || {
        echo "Error: Failed to export collection $SOURCE_COLLECTION from database $SOURCE_DB."
        exit 1
    }

    # Import into the target database
    mongoimport --uri="$CONNECTION_STRING/$TARGET_DB" --collection="$TARGET_COLLECTION" --file="$SOURCE_COLLECTION.json" || {
        echo "Error: Failed to import collection $SOURCE_COLLECTION into $TARGET_DB as $TARGET_COLLECTION."
        exit 1
    }

    # Clean up
    rm -f "$SOURCE_COLLECTION.json"

    echo "Successfully copied $SOURCE_COLLECTION from $SOURCE_DB to $TARGET_COLLECTION in $TARGET_DB."
}

# Main script logic
if [[ $# -lt 3 ]]; then
    print_usage
fi

COMMAND=$1
SOURCE_DB=$(echo "$2" | cut -d'/' -f1)
SOURCE_COLLECTION=$(echo "$2" | cut -d'/' -f2)
TARGET_DB=$(echo "$3" | cut -d'/' -f1)
TARGET_COLLECTION=$(echo "$3" | cut -d'/' -f2)

# Parse optional parameters
for arg in "$@"; do
    case $arg in
        --host=*)
            HOST="${arg#*=}"
            ;;
        --port=*)
            PORT="${arg#*=}"
            ;;
        --username=*)
            USERNAME="${arg#*=}"
            ;;
        --password=*)
            PASSWORD="${arg#*=}"
            ;;
        --uri=*)
            URI="${arg#*=}"
            ;;
        *)
            # Ignore other arguments (first three are positional)
            ;;
    esac
done

# Construct the MongoDB connection string
construct_connection_string

# Execute the appropriate function based on the command
case $COMMAND in
    mmv)
        mmv
        ;;
    mcp)
        mcp
        ;;
    *)
        echo "Unknown command: $COMMAND"
        print_usage
        ;;
esac
