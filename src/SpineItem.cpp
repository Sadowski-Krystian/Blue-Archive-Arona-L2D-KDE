#include "SpineItem.h"
#include <QSGGeometryNode>
#include <QSGTextureMaterial>
#include <QSGTransformNode>
#include <QQuickWindow>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <algorithm>

// 1. Texture Loader Bridge (Dynamic absolute paths)
class QtTextureLoader : public spine::TextureLoader {
public:
    QString basePath;

    void load(spine::AtlasPage& page, const spine::String& path) override {
        QFileInfo info(QString::fromUtf8(path.buffer()));
        QString fullPath = QDir(basePath).filePath(info.fileName());
        
                        // SpineItem.cpp - wewnątrz QtTextureLoader::load
        QImage loadedImage(fullPath);
        if (loadedImage.isNull()) {
            qWarning() << "CRITICAL: Image not found at" << fullPath;
        }

        // Konwersja do pre-multiplied alpha poprawia mieszanie krawędzi (brak czarnych obwódek)
        QImage* image = new QImage(loadedImage.convertToFormat(QImage::Format_ARGB32_Premultiplied));



        page.setRendererObject(image); 
        page.width = image->width();
        page.height = image->height();
    }

    void unload(void* texture) override {
        delete static_cast<QImage*>(texture);
    }
};

SpineItem::SpineItem(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
    m_textureLoader = new QtTextureLoader();
    m_timer.start();

    connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow* window) {
        if (window) {
            connect(window, &QQuickWindow::beforeSynchronizing, this, &SpineItem::updateAnimation);
        }
    });
}

SpineItem::~SpineItem() {
    delete m_animationState;
    delete m_animationStateData;
    delete m_skeleton;
    delete m_skeletonData;
    delete m_atlas;
    delete m_textureLoader;
    
    for (QSGTexture* tex : std::as_const(m_textures)) {
        delete tex;
    }
    m_textures.clear();
}

void SpineItem::setSkelSource(const QString &source) {
    if (m_skelSource != source) {
        m_skelSource = source;
        loadSkeleton();
        Q_EMIT sourceChanged();
    }
}

void SpineItem::setAtlasSource(const QString &source) {
    if (m_atlasSource != source) {
        m_atlasSource = source;
        loadSkeleton();
        Q_EMIT sourceChanged();
    }
}

void SpineItem::setAnimation(const QString &animationName) {
    m_animation = animationName;
    if (m_animationState && !m_animation.isEmpty()) {
        m_animationState->setAnimation(0, spine::String(m_animation.toUtf8().constData()), true);
    }
    Q_EMIT animationChanged();
}

void SpineItem::setTrackAnimation(int track, const QString &animationName, bool loop) {
    if (m_animationState && !animationName.isEmpty()) {
        m_animationState->setAnimation(track, spine::String(animationName.toUtf8().constData()), loop);
    }
}

void SpineItem::addTrackAnimation(int track, const QString &animationName, bool loop, float delay) {
    if (m_animationState && !animationName.isEmpty()) {
        m_animationState->addAnimation(track, spine::String(animationName.toUtf8().constData()), loop, delay);
    }
}

void SpineItem::clearTrack(int track) {
    if (m_animationState) {
        m_animationState->setEmptyAnimation(track, 0.0f);
    }
}

void SpineItem::loadSkeleton() {
    if (m_skelSource.isEmpty() || m_atlasSource.isEmpty()) return;

    delete m_animationState; m_animationState = nullptr;
    delete m_skeleton; m_skeleton = nullptr;
    delete m_skeletonData; m_skeletonData = nullptr;
    delete m_atlas; m_atlas = nullptr;

    QFileInfo atlasInfo(m_atlasSource);
    m_textureLoader->basePath = atlasInfo.path();

    spine::String atlasPath(m_atlasSource.toUtf8().constData());
    m_atlas = new spine::Atlas(atlasPath, m_textureLoader);

    spine::SkeletonBinary binary(m_atlas);
    binary.setScale(1.0f);

    spine::String skelPath(m_skelSource.toUtf8().constData());
    m_skeletonData = binary.readSkeletonDataFile(skelPath);

    if (!m_skeletonData) {
        qWarning() << "Failed to load skeleton data:" << binary.getError().buffer();
        return;
    }

    m_skeleton = new spine::Skeleton(m_skeletonData);
    m_animationStateData = new spine::AnimationStateData(m_skeletonData);
    m_animationState = new spine::AnimationState(m_animationStateData);

    if (!m_animation.isEmpty()) {
        setAnimation(m_animation);
    }
}

void SpineItem::updateAnimation() {
    if (m_paused) {
        return; 
    }
    if (!m_skeleton || !m_animationState) return;

    // Hard-cap the math calculations to ~30 FPS (33 milliseconds)
    if (m_timer.elapsed() < 33) {
        update(); // Tell Qt to keep the loop alive, but skip the heavy CPU math
        return;
    }

    float dt = m_timer.restart() / 1000.0f;
    
    m_animationState->update(dt);
    m_animationState->apply(*m_skeleton);

    // Inject manual QML bone coordinates before calculating world transforms
    for (auto it = m_overriddenBones.constBegin(); it != m_overriddenBones.constEnd(); ++it) {
        spine::Bone* bone = m_skeleton->findBone(spine::String(it.key().toUtf8().constData()));
        if (bone) {
            bone->setX(it.value().x());
            bone->setY(it.value().y());
        }
    }

    m_skeleton->updateWorldTransform();
    update();
}

void SpineItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    update();
}

void SpineItem::itemChange(ItemChange change, const ItemChangeData &value) {
    QQuickItem::itemChange(change, value);
    if (change == ItemVisibleHasChanged || change == ItemSceneChange) {
        update();
    }
}


QPointF SpineItem::getBonePosition(const QString &boneName) {
    if (m_skeleton) {
        spine::Bone* bone = m_skeleton->findBone(spine::String(boneName.toUtf8().constData()));
        if (bone) return QPointF(bone->getX(), bone->getY());
    }
    return QPointF(0, 0);
}

void SpineItem::setBonePosition(const QString &boneName, float x, float y) {
    m_overriddenBones.insert(boneName, QPointF(x, y));
}

void SpineItem::clearBonePosition(const QString &boneName) {
    m_overriddenBones.remove(boneName);
}

QSGNode *SpineItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
    if (!m_skeleton) return oldNode;

    QSGTransformNode* rootNode = static_cast<QSGTransformNode*>(oldNode);
    if (!rootNode) {
        rootNode = new QSGTransformNode();
    }

    float baseWidth = 2880.0f;
    float baseHeight = 1620.0f;
    float itemW = static_cast<float>(width());
    float itemH = static_cast<float>(height());
    float scale = std::max(itemW / baseWidth, itemH / baseHeight);
    if (scale <= 0.0f) scale = 1.0f;

    QMatrix4x4 matrix;
    matrix.translate(itemW / 2.0f, itemH / 2.0f);
    matrix.scale(scale, -scale);
    matrix.translate(0.0f, -900.0f);
    rootNode->setMatrix(matrix);

    // 1. Grab the first existing child node to start recycling
    QSGNode* currentNode = rootNode->firstChild();

    auto& drawOrder = m_skeleton->getDrawOrder();
    for (size_t i = 0, n = drawOrder.size(); i < n; ++i) {
        spine::Slot* slot = drawOrder[i];
        spine::Attachment* attachment = slot->getAttachment();
        if (!attachment) continue;

        QImage* image = nullptr;
        spine::Vector<float> vertices;
        spine::Vector<float> uvs;
        spine::Vector<unsigned short> indices;

        if (attachment->getRTTI().isExactly(spine::RegionAttachment::rtti)) {
            spine::RegionAttachment* region = static_cast<spine::RegionAttachment*>(attachment);
            spine::AtlasRegion* atlasRegion = static_cast<spine::AtlasRegion*>(region->getRendererObject());
            image = static_cast<QImage*>(atlasRegion->page->getRendererObject());
            
            vertices.setSize(8, 0);
            region->computeWorldVertices(slot->getBone(), vertices.buffer(), 0, 2);
            
            uvs.clear();
            for (size_t v = 0; v < region->getUVs().size(); ++v) uvs.add(region->getUVs()[v]);
            
            indices.clear();
            indices.add(0); indices.add(1); indices.add(2);
            indices.add(2); indices.add(3); indices.add(0);
        } else if (attachment->getRTTI().isExactly(spine::MeshAttachment::rtti)) {
            spine::MeshAttachment* mesh = static_cast<spine::MeshAttachment*>(attachment);
            spine::AtlasRegion* atlasRegion = static_cast<spine::AtlasRegion*>(mesh->getRendererObject());
            image = static_cast<QImage*>(atlasRegion->page->getRendererObject());
            
            vertices.setSize(mesh->getWorldVerticesLength(), 0);
            mesh->computeWorldVertices(*slot, 0, mesh->getWorldVerticesLength(), vertices.buffer(), 0, 2);
            
            uvs.clear();
            for (size_t v = 0; v < mesh->getUVs().size(); ++v) uvs.add(mesh->getUVs()[v]);
            
            indices.clear();
            for (size_t v = 0; v < mesh->getTriangles().size(); ++v) indices.add(mesh->getTriangles()[v]);
        } else {
            continue;
        }

        if (!image || image->isNull()) continue;

        QSGGeometryNode* node = nullptr;
        QSGGeometry* geometry = nullptr;
        QSGTextureMaterial* material = nullptr;

        // 2. Recycle the node if it exists, otherwise create a new one
        if (currentNode) {
            node = static_cast<QSGGeometryNode*>(currentNode);
            geometry = node->geometry();
            material = static_cast<QSGTextureMaterial*>(node->material());
            currentNode = currentNode->nextSibling();
        } else {
            node = new QSGGeometryNode();
            node->setFlag(QSGNode::OwnsGeometry);
            node->setFlag(QSGNode::OwnsMaterial);

            geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 0, 0);
            geometry->setDrawingMode(QSGGeometry::DrawTriangles);
            node->setGeometry(geometry);

            material = new QSGTextureMaterial();
            material->setFlag(QSGMaterial::Blending, true);
            material->setFiltering(QSGTexture::Linear);
            node->setMaterial(material);

            rootNode->appendChildNode(node);
        }

        // 3. Fast allocation: merely resizes the memory buffer without deleting the object
        geometry->allocate(vertices.size() / 2, indices.size());
        
        QSGGeometry::TexturedPoint2D* points = geometry->vertexDataAsTexturedPoint2D();
        for (size_t v = 0, pt = 0; v < vertices.size(); v += 2, ++pt) {
            points[pt].set(vertices[v], vertices[v + 1], uvs[v], uvs[v + 1]);
        }

        uint16_t* indexData = geometry->indexDataAsUShort();
        for (size_t ind = 0; ind < indices.size(); ++ind) {
            indexData[ind] = indices[ind];
        }

        QSGTexture* texture = m_textures.value(image, nullptr);
        if (!texture) {
            auto flags = static_cast<QQuickWindow::CreateTextureOption>(
                QQuickWindow::TextureHasAlphaChannel | QQuickWindow::TextureHasMipmaps
            );
            texture = window()->createTextureFromImage(*image, flags);
            texture->setFiltering(QSGTexture::Linear);
            texture->setMipmapFiltering(QSGTexture::Linear);
            texture->setHorizontalWrapMode(QSGTexture::ClampToEdge);
            texture->setVerticalWrapMode(QSGTexture::ClampToEdge);
            m_textures.insert(image, texture);
        }

        material->setTexture(texture);

        // 4. Critical: Tell the GPU that the data in this recycled node has changed
        node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    // 5. Clean up any leftover nodes if the new animation frame has fewer slots than the last one
    while (currentNode) {
        QSGNode* next = currentNode->nextSibling();
        rootNode->removeChildNode(currentNode);
        delete currentNode;
        currentNode = next;
    }

    return rootNode;
}