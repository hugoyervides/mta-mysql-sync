--Datos MySQL
local HOST = "127.0.0.1"
local USER = "isg"
local PASSWORD = "NSrv6ya9T01xBk83"
local DATABASE = "isg"
local conexion = false

--Funcion para establecer la conexion con el servidor MySQL
function startMySQLCon()
	--Desplegar debug
	outputDebugString("Intentando hacer conexion con el servidor MySQL...")
	--Establecer conexion MySQL
	conexion =  dbConnect( "mysql", "dbname="..DATABASE..";host="..HOST,USER,PASSWORD, "share=1" )
	if conexion ~= false then
		outputDebugString("Conexion MySQL Exitosa!")
	else
		outputDebugString("Error en la conexion MySQL! Deteniendo script",1)
		stopResource(getThisResource())
	end
end

--Funcion para ver si existe el usuario en la base de datos
function isUserOnDatabase(user)
	--Preparar el query para conseguir los usuarios con ese usernam
	local query=dbQuery(conexion,"SELECT member_id FROM core_members WHERE name='"..user.."'")
	local result, num_affected_rows, last_insert_id = dbPoll ( query, -1 )
	--Liberamos el resultado
	dbFree(query)
	if result == nil then
	    outputDebugString("El query no se completo por TimeOut",1)
	    return false
	elseif result == false then
	    local error_code,error_msg = num_affected_rows,last_insert_id
	    outputDebugString( "Error haciendo Query, codigo de error: " .. tostring(error_code) .. "  Mensaje: " .. tostring(error_msg),1)
	    return false
	else
	    --Ver si lo que nos llego no es nada
	    if #result==0 then
	    	--Regresamos false para indicar que no existe el usuario que se esta buscando
	    	outputDebugString("El usuario no esta registrado en la base de datos!",1)
	    	return false
	    else
	    	--Regresamos true para indicar que si existe
	    	return true
	    end
	end
	
end

--Funcion para ver si existe un record del usuario en la base de datos, en caso que no lo crea
function isThereUserRecord(user)
	--Preparamos el query
	local query=dbQuery(conexion,"SELECT CM.member_id, gameCash, goldCoins FROM core_members CM LEFT JOIN isg_data ISG ON CM.member_id=ISG.member_id WHERE name='"..user.."'")
	local result, num_affected_rows, last_insert_id = dbPoll(query,-1)
	--Liberamos el resultado
	dbFree(query)
	--COndicion para ver si regresamos algo y nos dio time out
	if result == nil then
		outputDebugString("El query no se completo por TimeOut",1)
		return false
	elseif result == false then
		local error_code,error_msg = num_affected_rows,last_insert_id
		outputDebugString("Error haciendo Query, codigo de error: "..tostring(erro_code).." Mensaje: ".. tostring(error_msg),1)
		return false
	else
		--Ver si no tenemos ningun resultado
		if(#result==0) then
			outputDebugString("No existe ningun usuario con ese nombre registrado en la base de datos")
			return false
		end
		--Ver si el valor del cash es false, en caso de serlo, significa que no se encuentran datos
		if result[1]["gameCash"] == false then
			outputDebugString("No existen registros de usuario que se quiere buscar, insertando nuevos registros en la base de datos",2)
			--Insertamos los datos con el memeber id
			local userID=result[1]["member_id"]
			local query=dbQuery(conexion,"INSERT INTO isg_data VALUES ("..userID..",0.0,0.0)")
			--ver si se pudo hacer el query
			local result=dbPoll(query,-1)
			--Liberamos el resultado
			dbFree(query)
			if result == nil then
				outputDebugString("El query no se completo por TimeOut",1)
				return false
			elseif result == false then
				outputDebugString("Error insertando datos en la base de datos",1)
				return false
			else
				outputDebugString("Registro del usuario "..user.." creado con exito!")
				return true
			end
		else
			--regresamos true
			return true
		end
	end
	--Refresar fasle por que nada mas paso
	return false
end

--Funcion para consultar datos de la base de datos del foro
function getUserData(user,type)
	--Ver si existe el usuario y si tiene registros
	if isUserOnDatabase(user) and isThereUserRecord(user) then
		--Conseguir el balance del usuario
		--Preparar query
		local query = dbQuery(conexion,"SELECT * FROM core_members CM JOIN isg_data ISG ON CM.member_id=ISG.member_id WHERE name='"..user.."'")
		local result = dbPoll(query,-1)
		--Ver si tenemos resultados
		if result == nil then
			outputDebugString("Time out haciendo query a la base de datos",1)
			return false
		elseif result == false then
			outputDebugString("No se pudo completar el query a la base de datos",1)
			return false
		else
			--Regresar el dato que nos pidio
			return result[1][type]
		end
	else
		return false
	end 
end
--Funcion para actualizar datos en la base de datos del foro
function updateUserData(user,type,newdata)
	--Ver si exist el usuario y si tiene registros
	if isUserOnDatabase(user) and isThereUserRecord(user) then
		--Hacer query para insertar los datos
		local query=dbQuery(conexion,'UPDATE isg_data SET '..type..'='..newdata..' WHERE member_id IN (SELECT member_id FROM core_members WHERE name="'..user..'")')
		local result=dbPoll(query,-1)
		--ver si tenemos exito
		if result == nil then
			outputDebugString("Time out haciendo query a la base de datos",1)
		elseif result == false then
			outputDebugString("No se pudo completar el query a la base de datos",1)
		else
			--regresar true
			return true
		end
	else
		return false
	end
end
--STARTUP
--Iniciar conexion MySQL
startMySQLCon()
