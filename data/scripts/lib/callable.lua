
if onServer() then

function callable(namespace, func)
    if namespace then
        namespace.Callable = namespace.Callable or {}
        namespace.Callable[func] = namespace[func]
    else
        Callable = Callable or {}
        Callable[func] = _G[func]
    end
end

else

function callable() end

end
