#! /bin/bash

# Variable para ejecutar consultas SQL (PSQL)
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n" 

MAIN_MENU() {
  # Si se pasa un argumento (mensaje de error), se imprime
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # 1. Mostrar lista de servicios
  # Obtenemos los servicios y los leemos línea por línea
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  
  echo "$SERVICES" | while read SERVICE_ID BAR NAME
  do
    echo "$SERVICE_ID) $NAME"
  done

  # 2. Leer la selección del usuario
  read SERVICE_ID_SELECTED

  # 3. Verificar si el servicio existe en la BD
  # Si no es un número, la consulta fallará o dará vacío, pero mejor validamos el resultado directo
  SERVICE_NAME_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

  # Si el servicio no existe (la variable vuelve vacía)
  if [[ -z $SERVICE_NAME_SELECTED ]]
  then
    # Enviamos de vuelta al menú con el mensaje de error
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    # --- FLUJO DE AGENDA ---

    # 4. Pedir teléfono
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE

    # 5. Buscar cliente por teléfono
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

    # Si no existe el cliente (nombre vacío)
    if [[ -z $CUSTOMER_NAME ]]
    then
      echo -e "\nI don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME

      # Insertar nuevo cliente
      INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')") 
    fi

    # 6. Formatear nombres (quitar espacios en blanco que agrega PSQL)
    # Esto es CRÍTICO para pasar los tests de FreeCodeCamp
    SERVICE_NAME_FORMATTED=$(echo $SERVICE_NAME_SELECTED | sed -r 's/^ *| *$//g')
    CUSTOMER_NAME_FORMATTED=$(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')

    # 7. Pedir la hora de la cita
    echo -e "\nWhat time would you like your $SERVICE_NAME_FORMATTED, $CUSTOMER_NAME_FORMATTED?"
    read SERVICE_TIME

    # 8. Obtener el ID del cliente (necesario para la tabla appointments)
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

    # 9. Insertar la cita
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

    # 10. Mensaje final
    echo -e "\nI have put you down for a $SERVICE_NAME_FORMATTED at $SERVICE_TIME, $CUSTOMER_NAME_FORMATTED."
  fi
}

# Ejecutar la función principal
MAIN_MENU

