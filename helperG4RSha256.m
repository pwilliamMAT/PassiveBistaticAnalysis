function digest = helperG4RSha256(inputValue, options)
%HELPERG4RSHA256 Compute a fail-closed SHA-256 fingerprint.

arguments
    inputValue
    options.InputType (1,1) string = "auto"
end

inputType = lower(options.InputType);

if inputType == "auto"
    if (ischar(inputValue) || ...
            (isstring(inputValue) && isscalar(inputValue))) && ...
            isfile(string(inputValue))
        inputType = "file";
    else
        inputType = "value";
    end
end

if ~ismember(inputType, ["file", "value", "text"])
    error("helperG4RSha256:InvalidInputType", ...
        "InputType must be auto, file, value, or text.");
end

if ~usejava("jvm")
    error("helperG4RSha256:JavaUnavailable", ...
        "SHA-256 requires the MATLAB JVM in this implementation.");
end

messageDigest = java.security.MessageDigest.getInstance("SHA-256");

if inputType == "file"
    localUpdateFromFile(messageDigest, string(inputValue));
elseif inputType == "text"
    bytes = unicode2native(char(string(inputValue)), "UTF-8");
    localUpdateDigest(messageDigest, uint8(bytes));
else
    bytes = localSerializeValue(inputValue);
    localUpdateDigest(messageDigest, bytes);
end

signedDigest = int8(messageDigest.digest());
digestBytes = typecast(signedDigest, "uint8");
digest = lower(string(reshape(dec2hex(digestBytes, 2).', 1, [])));

end

function localUpdateFromFile(messageDigest, filePath)

if ~isfile(filePath)
    error("helperG4RSha256:MissingFile", ...
        "Cannot fingerprint missing file %s.", filePath);
end

fileIdentifier = fopen(filePath, "rb");

if fileIdentifier < 0
    error("helperG4RSha256:OpenFailed", ...
        "Cannot open %s for fingerprinting.", filePath);
end

cleanup = onCleanup(@() fclose(fileIdentifier));
chunkSize = 4 .* 1024 .* 1024;

while true
    bytes = fread(fileIdentifier, chunkSize, "*uint8");

    if isempty(bytes)
        break
    end

    localUpdateDigest(messageDigest, bytes);
end

clear cleanup

end

function bytes = localSerializeValue(inputValue)

if isnumeric(inputValue) || islogical(inputValue)
    header = struct( ...
        "Class", string(class(inputValue)), ...
        "Size", double(size(inputValue)), ...
        "IsReal", logical(isreal(inputValue)));
    headerBytes = unicode2native(jsonencode(header), "UTF-8");
    realBytes = localNumericBytes(real(inputValue));

    if isreal(inputValue)
        imaginaryBytes = zeros(0, 1, "uint8");
    else
        imaginaryBytes = localNumericBytes(imag(inputValue));
    end

    bytes = [ ...
        uint8(headerBytes(:)); ...
        uint8(0); ...
        realBytes(:); ...
        uint8(0); ...
        imaginaryBytes(:) ...
        ];
    return
end

if ischar(inputValue) || isstring(inputValue)
    text = jsonencode(string(inputValue));
    bytes = uint8(unicode2native(text, "UTF-8"));
    bytes = bytes(:);
    return
end

if istable(inputValue)
    inputValue = table2struct(inputValue);
end

try
    text = jsonencode(inputValue);
catch encodingException
    error("helperG4RSha256:UnsupportedValue", ...
        "Value cannot be serialized deterministically: %s", ...
        encodingException.message);
end

bytes = uint8(unicode2native(text, "UTF-8"));
bytes = bytes(:);

end

function bytes = localNumericBytes(value)

if islogical(value)
    bytes = uint8(value(:));
else
    bytes = typecast(value(:), "uint8");
end

end

function localUpdateDigest(messageDigest, bytes)

if isempty(bytes)
    return
end

signedBytes = typecast(uint8(bytes(:)), "int8");
messageDigest.update(signedBytes);

end
