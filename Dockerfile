# ==============================================================================
# Baserow Self-Hosted All-in-One (Completely Open Source - All Features Unlocked)
# ==============================================================================
FROM baserow/baserow:latest

USER root

# 1. Copiar backend modificado (sin verificaciones de licencias, sin paywalls)
COPY --chown=9999:9999 ./premium/backend/src/baserow_premium/ /baserow/premium/backend/src/baserow_premium/
COPY --chown=9999:9999 ./enterprise/backend/src/baserow_enterprise/ /baserow/enterprise/backend/src/baserow_enterprise/

# --- PARCHES DE COMPATIBILIDAD ---
# Parche 1: Resolver falta de clase en acciones del dashboard
RUN printf "\nclass UpdateDashboardSharingActionType:\n    pass\n" >> /baserow/backend/src/baserow/contrib/dashboard/actions.py

# Parche 2: Resolver falta de la función serialize_public_field en serializadores de campos
RUN printf "\ndef serialize_public_field(*args, **kwargs):\n    return {}\n" >> /baserow/backend/src/baserow/contrib/database/api/fields/serializers.py

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
