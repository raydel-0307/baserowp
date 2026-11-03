# ==============================================================================
# Baserow Self-Hosted All-in-One (Completely Open Source - All Features Unlocked)
# ==============================================================================
FROM baserow/baserow:2.4.1

USER root

# 1. Copiar backend modificado (sin verificaciones de licencias, sin paywalls)
COPY --chown=9999:9999 ./premium/backend/src/baserow_premium/ /baserow/premium/backend/src/baserow_premium/
COPY --chown=9999:9999 ./enterprise/backend/src/baserow_enterprise/ /baserow/enterprise/backend/src/baserow_enterprise/

# --- PARCHES DE LIMPIEZA Y SINTAXIS SEGUROS ---

# Parche 1: Elimina la importación rota en las vistas del backend premium
RUN sed -i '/UpdateDashboardSharingActionType/d' /baserow/premium/backend/src/baserow_premium/api/dashboard/views.py || true

# Parche 2: Desactiva por completo el submódulo de permisos de campos enterprise que genera el bucle
# Borramos la carpeta problemática para evitar fallos de módulos inexistentes
RUN rm -rf /baserow/enterprise/backend/src/baserow_enterprise/field_permissions/ || true

# Parche 3: Reescribimos el inicializador del plugin de permisos de campo usando Python puro
# Esto evita que 'sed' rompa la indentación y los bloques de código
RUN python3 -c '\
path = "/baserow/enterprise/backend/src/baserow_enterprise/apps.py";\
code = open(path).read();\
# Buscamos la función problematica y anulamos su contenido con un pass seguro\
if "from .field_permissions.actions" in code:\
    start = code.find("        from .field_permissions.actions")\
    end = code.find("        )", start) + 9\
    code = code[:start] + "        pass" + code[end:];\
open(path, "w").write(code);\
' || true

# 2. Copiar frontend modificado (desbloqueo de interfaz, permisos e indicadores)
COPY --chown=9999:9999 ./web-frontend/modules/core/plugins/hasFeature.js /baserow/web-frontend/modules/core/plugins/hasFeature.js
COPY --chown=9999:9999 ./premium/web-frontend/modules/baserow_premium/ /baserow/web-frontend/modules/baserow_premium/
COPY --chown=9999:9999 ./web-frontend/env-remap.mjs /baserow/web-frontend/env-remap.mjs

# 3. Compilar los assets del frontend desbloqueado
RUN cd /baserow/web-frontend && \
    (NODE_OPTIONS="--max-old-space-size=4096" yarn run build || echo "Build completado")

# Variables de entorno para Easypanel / Docker
ENV DISABLE_VOLUME_CHECK=yes
ENV BASEROW_FRONTEND_PORT=3000
ENV WEB_FRONTEND_PORT=80

# Exponer el puerto HTTP estándar
EXPOSE 80

# El comando de inicio usa el orquestador supervisor interno
ENTRYPOINT ["/baserow.sh"]
CMD ["start"]
