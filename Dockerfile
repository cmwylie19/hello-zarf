# Stage 1
FROM scratch

LABEL description="hello-zarf" \
      maintainer="Casey Wylie casewylie@gmail.com"

COPY ./hello-zarf /