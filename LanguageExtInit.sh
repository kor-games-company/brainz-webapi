#!/bin/bash

# Убедитесь, что скрипт останавливается при ошибках
set -e

# Путь к корневой директории решения (где находится файл .sln)
SOLUTION_ROOT=$(pwd)

# Путь к GlobalUsings.cs
GLOBAL_USINGS_PATH="$SOLUTION_ROOT/GlobalUsings.cs"

# Создание GlobalUsings.cs, если он не существует
if [ ! -f "$GLOBAL_USINGS_PATH" ]; then
    echo "Создание GlobalUsings.cs..."
    cat <<EOL > "$GLOBAL_USINGS_PATH"
global using LanguageExt;
global using static LanguageExt.Prelude;
EOL
    echo "GlobalUsings.cs создан."
else
    echo "GlobalUsings.cs уже существует."
fi

# Поиск всех .csproj файлов в решении
echo "Поиск всех .csproj файлов..."
PROJECTS=$(find . -name "*.csproj")

# Установка пакета LanguageExt.Core версии 5.0.0-beta-*
echo "Установка пакета LanguageExt.Core версии 5.0.0-beta-* во все проекты..."
for PROJECT in $PROJECTS; do
    echo "Добавление LanguageExt.Core к $PROJECT..."
    dotnet add "$PROJECT" package LanguageExt.Core --version "5.0.0-beta-*"
done
echo "Пакет LanguageExt.Core установлен во все проекты."

# Функция для добавления GlobalUsings.cs как связанного файла в .csproj
add_global_usings() {
    local project_file="$1"
    local project_dir
    project_dir=$(dirname "$project_file")
    
    # Вычисление относительного пути от проекта к GlobalUsings.cs
    # Предполагается, что GlobalUsings.cs находится в корне решения
    relative_path=$(realpath --relative-to="$project_dir" "$GLOBAL_USINGS_PATH")
    
    # Проверка, уже ли добавлен GlobalUsings.cs
    if grep -q "<Compile Include=\"$relative_path\"" "$project_file"; then
        echo "GlobalUsings.cs уже добавлен к $project_file."
    else
        echo "Добавление GlobalUsings.cs к $project_file..."
        # Вставка Compile Include перед закрывающим тегом </Project>
        sed -i "/<\/Project>/i\  <ItemGroup>\n    <Compile Include=\"$relative_path\" Link=\"GlobalUsings.cs\" />\n  </ItemGroup>" "$project_file"
        echo "GlobalUsings.cs добавлен к $project_file."
    fi
}

# Добавление GlobalUsings.cs как связанного файла во все проекты
echo "Добавление GlobalUsings.cs как связанного файла во все проекты..."
for PROJECT in $PROJECTS; do
    add_global_usings "$PROJECT"
done
echo "GlobalUsings.cs успешно добавлен во все проекты."

echo "Настройка завершена успешно."
