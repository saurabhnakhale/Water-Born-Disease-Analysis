param([int]$Port = 8085)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try {
    $listener.Start()
    Write-Host "HTTP server running at http://localhost:$Port/"
} catch {
    Write-Host "Failed to start server: $_"
    exit 1
}

$baseDir = (Get-Location).Path

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $urlPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($urlPath)) { $urlPath = 'index.html' }
        $filePath = Join-Path $baseDir $urlPath
        
        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            if ($filePath.EndsWith('.html')) { $response.ContentType = 'text/html; charset=utf-8' }
            elseif ($filePath.EndsWith('.js')) { $response.ContentType = 'application/javascript; charset=utf-8' }
            elseif ($filePath.EndsWith('.json')) { $response.ContentType = 'application/json; charset=utf-8' }
            elseif ($filePath.EndsWith('.css')) { $response.ContentType = 'text/css; charset=utf-8' }
            
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("File Not Found")
            $response.ContentLength64 = $errBytes.Length
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.OutputStream.Close()
    } catch {
        # ignore aborts
    }
}
