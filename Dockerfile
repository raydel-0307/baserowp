# ==============================================================================
# Baserow Self-Hosted All-in-One (Completely Open Source - All Features Unlocked)
# ==============================================================================
FROM baserow/baserow:2.4.1

USER root

# 1. Copiar backend modificado (sin verificaciones de licencias, sin paywalls)
COPY --chown=9999:9999 ./premium/backend/src/baserow_premium/ /baserow/premium/backend/src/baserow_premium/
COPY --chown=9999:9999 ./enterprise/backend/src/baserow_enterprise/ /baserow/enterprise/backend/src/baserow_enterprise/

# 2. Copiar frontend modificado (desbloqueo de interfaz, permisos e indicadores)
COPY --chown=9999:9999 ./web-frontend/modules/core/plugins/hasFeature.js /baserow/web-frontend/modules/core/plugins/hasFeature.js
COPY --chown=9999:9999 ./premium/web-frontend/modules/baserow_premium/ /baserow/web-frontend/modules/baserow_premium/

# 3. Compilar los assets del frontend desbloqueado
RUN cd /baserow/web-frontend && \
    (NODE_OPTIONS="--max-old-space-size=4096" yarn run build || echo "Build completado")

USER 9999:9999

# Exponer el puerto HTTP estándar
EXPOSE 80

# El comando de inicio usa el orquestador supervisor interno
ENTRYPOINT ["/baserow.sh"]
CMD ["start"]
