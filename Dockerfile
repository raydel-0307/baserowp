# ==============================================================================
# Baserow Self-Hosted All-in-One (Completely Open Source - All Features Unlocked)
# ==============================================================================
FROM baserow/baserow:2.4.1

USER root

# 1. Copiar backend modificado (sin verificaciones de licencias, sin paywalls)
COPY --chown=9999:9999 ./premium/backend/src/baserow_premium/ /baserow/premium/backend/src/baserow_premium/
COPY --chown=9999:9999 ./enterprise/backend/src/baserow_enterprise/ /baserow/enterprise/backend/src/baserow_enterprise/

# --- SOLUCIÓN DE RAÍZ PARA ERRORES DE IMPORTACIÓN ---
# Elimina la importación rota en las vistas del backend premium (UpdateDashboardSharingActionType)
RUN sed -i '/UpdateDashboardSharingActionType/d' /baserow/premium/backend/src/baserow_premium/api/dashboard/views.py || true

# Elimina el archivo de permisos de campos enterprise que busca 'subject_options' (módulo inexistente en el core)
RUN rm -rf /baserow/enterprise/backend/src/baserow_enterprise/field_permissions/ || true
# Limpia la inicialización del módulo eliminado para que Django no lo busque al arrancar
RUN sed -i '/field_permissions/d' /baserow/enterprise/backend/src/baserow_enterprise/apps.py || true

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
